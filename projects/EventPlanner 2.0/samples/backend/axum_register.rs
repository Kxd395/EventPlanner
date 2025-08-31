// Cargo.toml deps (example):
// axum = "0.7"
// serde = { version = "1", features = ["derive"] }
// serde_json = "1"
// hmac = "0.12"
// sha2 = "0.10"
// base64 = "0.22"
// time = "0.3"
// tokio = { version = "1", features = ["macros", "rt-multi-thread"] }

use axum::{routing::post, extract::{Path, State}, Json, Router};
use axum::http::StatusCode;
use hmac::{Hmac, Mac};
use serde::Deserialize;
use serde_json::{json, Value};
use sha2::Sha256;
use std::sync::Arc;
use time::OffsetDateTime;
use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine as _};

#[derive(Clone)]
struct AppState {
    // Replace with your real lookup (DB)
    get_event_secret: Arc<dyn Fn(&str) -> Option<String> + Send + Sync>,
}

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
    let Some(secret) = (st.get_event_secret)(&event) else {
        return (StatusCode::BAD_REQUEST, Json(json!({"error":"unknown_event"})));
    };
    if !verify(&r.event_id, r.exp, &r.token, &secret) {
        return (StatusCode::FORBIDDEN, Json(json!({"error":"bad_token"})));
    }

    // TODO:
    // 1) Upsert member by email/phone (return member_id)
    // 2) Upsert attendee { event_id, member_id, status="preregistered", source="public_form" }
    let attendee_id = "att_123"; // <-- replace with DB result
    let member_id = "mem_456";   // <-- replace with DB result

    (StatusCode::CREATED, Json(json!({
        "status": "ok",
        "attendee_id": attendee_id,
        "member_id": member_id,
        "state": "preregistered"
    })))
}

#[tokio::main]
async fn main() {
    let st = AppState {
        get_event_secret: Arc::new(|_eid| Some("EVENT_SECRET_FROM_DB".to_string())),
    };
    let app = Router::new()
        .route("/api/events/:id/registrations", post(register))
        .with_state(st);

    axum::Server::bind(&"0.0.0.0:8787".parse().unwrap())
        .serve(app.into_make_service())
        .await
        .unwrap();
}

