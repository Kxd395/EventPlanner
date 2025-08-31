// Cargo.toml deps (example):
// axum = "0.7"
// serde = { version = "1", features = ["derive"] }
// serde_json = "1"
// hmac = "0.12"
// sha2 = "0.10"
// base64 = "0.22"
// time = "0.3"
// tokio = { version = "1", features = ["macros", "rt-multi-thread"] }
// rusqlite = { version = "0.31", features = ["bundled"] }
// uuid = { version = "1", features = ["v4"] }

use axum::{routing::post, extract::{Path, State}, Json, Router};
use axum::http::StatusCode;
use hmac::{Hmac, Mac};
use serde::Deserialize;
use serde_json::{json, Value};
use sha2::Sha256;
use std::sync::Arc;
use time::OffsetDateTime;
use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine as _};
use rusqlite::{Connection, params};
use uuid::Uuid;

#[derive(Clone)]
struct AppState { db_path: Arc<String> }

#[derive(Deserialize)]
struct Reg {
    event_id: String,
    token: String,
    exp: i64,
    first_name: String,
    last_name: String,
    email: String,
    phone: Option<String>,
    company: Option<String>,
}

fn verify(event_id: &str, exp: i64, token: &str, secret: &str) -> bool {
    if OffsetDateTime::now_utc().unix_timestamp() > exp {
        return false;
    }
    let msg = format!("{event_id}|{exp}");
    let mut mac = Hmac::<Sha256>::new_from_slice(secret.as_bytes()).unwrap();
    mac.update(msg.as_bytes());
    match URL_SAFE_NO_PAD.decode(token) {
        Ok(sig) => mac.verify_slice(&sig).is_ok(),
        Err(_) => false,
    }
}

async fn register(Path(event): Path<String>, State(st): State<AppState>, Json(r): Json<Reg>)
    -> (StatusCode, Json<Value>)
{
    if r.event_id != event {
        return (StatusCode::BAD_REQUEST, Json(json!({"error":"bad_event"})));
    }

    // Open DB per request (simple and safe for sample)
    let conn = match Connection::open(st.db_path.as_str()) {
        Ok(c) => c,
        Err(e) => return (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({"error":"db_open_failed","detail":e.to_string()}))),
    };

    // Verify event + token
    let secret: Option<String> = conn.query_row(
        "SELECT public_secret FROM events WHERE id = ?1",
        params![&event],
        |row| row.get(0)
    ).ok();
    let Some(secret) = secret else { return (StatusCode::BAD_REQUEST, Json(json!({"error":"unknown_event"}))); };
    if !verify(&r.event_id, r.exp, &r.token, &secret) {
        return (StatusCode::FORBIDDEN, Json(json!({"error":"bad_token"})));
    }

    // Upsert member by email
    let mut member_id: Option<String> = conn
        .query_row("SELECT id FROM members WHERE email = ?1", params![&r.email], |row| row.get(0))
        .ok();
    if member_id.is_none() {
        let mid = Uuid::new_v4().to_string();
        let res = conn.execute(
            "INSERT INTO members (id, email, first_name, last_name, phone, company, created_at, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, STRFTIME('%Y-%m-%dT%H:%M:%SZ','now'), STRFTIME('%Y-%m-%dT%H:%M:%SZ','now'))",
            params![&mid, &r.email, &r.first_name, &r.last_name, &r.phone, &r.company],
        );
        if res.is_err() {
            return (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({"error":"member_upsert_failed"})));
        }
        member_id = Some(mid);
    } else {
        let _ = conn.execute(
            "UPDATE members SET first_name=?1, last_name=?2, phone=?3, company=?4, updated_at=STRFTIME('%Y-%m-%dT%H:%M:%SZ','now') WHERE id=?5",
            params![&r.first_name, &r.last_name, &r.phone, &r.company, &member_id.as_ref().unwrap()],
        );
    }
    let member_id = member_id.unwrap();

    // Upsert attendee as preregistered
    let att_existing: Option<String> = conn
        .query_row("SELECT id FROM attendees WHERE event_id=?1 AND member_id=?2", params![&event, &member_id], |row| row.get(0))
        .ok();
    let attendee_id = if let Some(aid) = att_existing { aid } else {
        let aid = Uuid::new_v4().to_string();
        let res = conn.execute(
            "INSERT INTO attendees (id, event_id, member_id, status, confirmed, source, created_at, updated_at)
             VALUES (?1, ?2, ?3, 'preregistered', 0, 'public_form', STRFTIME('%Y-%m-%dT%H:%M:%SZ','now'), STRFTIME('%Y-%m-%dT%H:%M:%SZ','now'))",
            params![&aid, &event, &member_id],
        );
        if res.is_err() {
            return (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({"error":"attendee_upsert_failed"})));
        }
        aid
    };

    (StatusCode::CREATED, Json(json!({
        "status": "ok",
        "attendee_id": attendee_id,
        "member_id": member_id,
        "state": "preregistered"
    })))
}

fn init_db(db_path: &str) -> anyhow::Result<()> {
    let conn = Connection::open(db_path)?;
    conn.execute_batch(
        r#"
        CREATE TABLE IF NOT EXISTS events (
            id TEXT PRIMARY KEY,
            name TEXT,
            public_secret TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS members (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE,
            first_name TEXT,
            last_name TEXT,
            phone TEXT,
            company TEXT,
            created_at TEXT,
            updated_at TEXT
        );
        CREATE TABLE IF NOT EXISTS attendees (
            id TEXT PRIMARY KEY,
            event_id TEXT NOT NULL,
            member_id TEXT NOT NULL,
            status TEXT NOT NULL,
            confirmed INTEGER DEFAULT 0,
            source TEXT,
            checked_in_at TEXT,
            dna_at TEXT,
            created_at TEXT,
            updated_at TEXT,
            UNIQUE(event_id, member_id)
        );
        "#,
    )?;
    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let db_path = std::env::var("EDP_DB").unwrap_or_else(|_| "edp_backend.db".into());
    init_db(&db_path)?;

    // Optional: seed a default event via env (for quick start)
    if let (Ok(eid), Ok(secret)) = (std::env::var("EDP_EVENT_ID"), std::env::var("EDP_EVENT_SECRET")) {
        let conn = Connection::open(&db_path)?;
        let _ = conn.execute(
            "INSERT OR IGNORE INTO events (id, name, public_secret) VALUES (?1, ?2, ?3)",
            params![eid, "Seed Event", secret],
        );
    }

    let st = AppState { db_path: Arc::new(db_path) };
    let app = Router::new()
        .route("/api/events/:id/registrations", post(register))
        .with_state(st);

    axum::Server::bind(&"0.0.0.0:8787".parse().unwrap())
        .serve(app.into_make_service())
        .await?;
    Ok(())
}
