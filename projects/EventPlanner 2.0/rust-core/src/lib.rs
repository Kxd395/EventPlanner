//! EventDeskPro core domain (SSOT) — status model and validation

pub mod status {
    #[repr(C)]
    #[derive(Debug, Copy, Clone, PartialEq, Eq)]
    pub enum AttendeeStatus {
        Preregistered = 0,
        Walkin = 1,
        Checkedin = 2,
        Dna = 3,
    }

    impl AttendeeStatus {
        pub fn as_str(&self) -> &'static str {
            match self {
                AttendeeStatus::Preregistered => "preregistered",
                AttendeeStatus::Walkin => "walkin",
                AttendeeStatus::Checkedin => "checkedin",
                AttendeeStatus::Dna => "dna",
            }
        }

        pub fn from_str(s: &str) -> Option<Self> {
            match s {
                "preregistered" => Some(AttendeeStatus::Preregistered),
                "walkin" => Some(AttendeeStatus::Walkin),
                "checkedin" => Some(AttendeeStatus::Checkedin),
                "dna" => Some(AttendeeStatus::Dna),
                _ => None,
            }
        }
    }
}

pub mod validate {
    use super::status::AttendeeStatus;

    #[repr(C)]
    #[derive(Debug, Copy, Clone, PartialEq, Eq)]
    pub enum TransitionCheck {
        Ok = 0,
        NeedsReason = 1,
        NeedsManagerOverride = 2,
    }

    /// SSOT transition validation (see docs/ssot/SSOT.md)
    pub fn validate_status_transition(
        current: AttendeeStatus,
        new_status: AttendeeStatus,
        event_in_progress: bool,
        has_manager_override: bool,
    ) -> TransitionCheck {
        // Early DNA requires manager override
        if matches!(new_status, AttendeeStatus::Dna) && event_in_progress && !has_manager_override {
            return TransitionCheck::NeedsManagerOverride;
        }
        // Undo from checked-in requires a reason (UI must enforce capture)
        if matches!(current, AttendeeStatus::Checkedin) && !matches!(new_status, AttendeeStatus::Checkedin) {
            return TransitionCheck::NeedsReason;
        }
        TransitionCheck::Ok
    }
}

pub mod util {
    use super::status::AttendeeStatus;

    /// Normalize free-form status strings to canonical SSOT codes.
    /// Accepts common legacy terms and returns canonical enum.
    pub fn normalize_status_str(s: &str) -> Option<AttendeeStatus> {
        let ls = s.trim().to_lowercase();
        match ls.as_str() {
            // canonical
            "preregistered" | "pre-registered" | "pre_registered" | "pre reg" | "pre-reg" | "registered" | "reg" =>
                Some(AttendeeStatus::Preregistered),
            "walkin" | "walk-in" | "walk_in" | "walk in" => Some(AttendeeStatus::Walkin),
            "checkedin" | "checked-in" | "checked_in" | "checked in" | "present" | "attended" =>
                Some(AttendeeStatus::Checkedin),
            "dna" | "did not attend" | "did_not_attend" | "no show" | "no_show" | "noshow" | "absent" =>
                Some(AttendeeStatus::Dna),
            _ => None,
        }
    }

    /// Whether auto-rollover should mark DNA given event end time and grace seconds.
    /// epoch parameters are seconds since UNIX epoch (UTC).
    pub fn auto_rollover_due(event_end_epoch_s: i64, grace_seconds: i64, now_epoch_s: i64) -> bool {
        now_epoch_s >= event_end_epoch_s.saturating_add(grace_seconds)
    }
}

pub mod csvops {
    use serde::Serialize;
    use std::collections::HashSet;

    #[derive(Debug, Serialize)]
    pub struct PreviewMetrics {
        pub total: usize,
        pub valid: usize,
        pub duplicates: usize,
        pub errors: usize,
    }

    #[derive(Debug, Serialize)]
    pub struct RowError {
        pub row: u64,
        pub error: String,
    }

    #[derive(Debug, Serialize)]
    pub struct PreviewResult {
        pub totals: PreviewMetrics,
        pub duplicate_emails: Vec<String>,
        pub errors: Vec<RowError>,
    }

    /// Preview CSV import: compute totals, errors, and intra-file duplicate emails.
    pub fn preview_csv_text(csv_text: &str) -> Result<PreviewResult, String> {
        let mut rdr = csv::ReaderBuilder::new()
            .flexible(true)
            .trim(csv::Trim::All)
            .from_reader(csv_text.as_bytes());

        let headers = rdr.headers().map_err(|e| e.to_string())?.clone();

        // Map useful columns
        let mut email_idx: Option<usize> = None;
        let mut name_idx: Option<usize> = None;
        let mut first_idx: Option<usize> = None;
        let mut last_idx: Option<usize> = None;
        for (i, h) in headers.iter().enumerate() {
            let key = h.to_lowercase();
            match key.as_str() {
                "email" => email_idx = Some(i),
                "name" => name_idx = Some(i),
                "firstname" | "first_name" | "first" => first_idx = Some(i),
                "lastname" | "last_name" | "last" => last_idx = Some(i),
                _ => {}
            }
        }

        let mut totals = PreviewMetrics { total: 0, valid: 0, duplicates: 0, errors: 0 };
        let mut dup_emails: Vec<String> = Vec::new();
        let mut seen_emails: HashSet<String> = HashSet::new();
        let mut row_errors: Vec<RowError> = Vec::new();

        for (i, rec_res) in rdr.records().enumerate() {
            let row_num = (i as u64) + 2; // account for header row
            totals.total += 1;
            let rec = match rec_res { Ok(r) => r, Err(e) => { totals.errors += 1; row_errors.push(RowError{ row: row_num, error: format!("row_error: {}", e) }); continue; } };

            // derive email/name
            let email = email_idx.and_then(|idx| rec.get(idx)).unwrap_or("").trim().to_lowercase();
            let name = name_idx.and_then(|idx| rec.get(idx)).unwrap_or("").trim().to_string();
            let first = first_idx.and_then(|idx| rec.get(idx)).unwrap_or("").trim().to_string();
            let last = last_idx.and_then(|idx| rec.get(idx)).unwrap_or("").trim().to_string();
            let has_name = !name.is_empty() || !first.is_empty() || !last.is_empty();

            if email.is_empty() && !has_name {
                totals.errors += 1;
                row_errors.push(RowError{ row: row_num, error: "row_error: missing required (email or name)".into() });
                continue;
            }

            if !email.is_empty() {
                if !seen_emails.insert(email.clone()) {
                    totals.duplicates += 1;
                    dup_emails.push(email);
                    // Still considered valid for preview; commit will decide handling
                }
            }

            totals.valid += 1;
        }

        Ok(PreviewResult { totals, duplicate_emails: dup_emails, errors: row_errors })
    }
}

pub mod db {
    use once_cell::sync::OnceCell;
    use rusqlite::{params, Connection, OptionalExtension};
    use uuid::Uuid;
    use crate::util::normalize_status_str;
    use crate::status::AttendeeStatus;
    use crate::validate::{validate_status_transition, TransitionCheck};

    static DB_PATH: OnceCell<String> = OnceCell::new();

    pub fn set_db_path(path: &str) -> bool {
        DB_PATH.set(path.to_string()).is_ok()
    }

    fn open_conn() -> rusqlite::Result<Connection> {
        let conn = match DB_PATH.get() {
            Some(p) if p == ":memory:" => Connection::open_in_memory(),
            Some(p) => Connection::open(p),
            None => Connection::open_in_memory(),
        }?;

        // Set pragmatic defaults for reliability and performance.
        // - Enforce foreign keys
        // - Use WAL for concurrency (single writer, many readers)
        // - Tune durability/perf balance
        // - Avoid immediate lock errors under mild contention
        conn.execute_batch(
            "PRAGMA foreign_keys=ON;\nPRAGMA journal_mode=WAL;\nPRAGMA synchronous=NORMAL;\nPRAGMA busy_timeout=5000;",
        )?;

        Ok(conn)
    }

    pub fn apply_schema(conn: &Connection) -> rusqlite::Result<()> {
        let schema = include_str!("../../docs/db/SCHEMA.sql");
        conn.execute_batch(schema)?;
        // Lightweight migration: add status_v2 column if missing (ignore failure if exists)
        let _ = conn.execute_batch(
            "ALTER TABLE event_attendance ADD COLUMN status_v2 TEXT CHECK (status_v2 IN ('preregistered','walkin','checkedin','dna'));\nCREATE INDEX IF NOT EXISTS idx_event_attendance_status_v2 ON event_attendance(status_v2);",
        );
        Ok(())
    }

    fn try_set_status_v2(tx: &rusqlite::Transaction<'_>, attendance_id: &str, status: &str) {
        // Attempt to write status_v2; ignore if column does not exist
        let _ = tx.execute(
            "UPDATE event_attendance SET status_v2=?1 WHERE id=?2",
            params![status, attendance_id],
        );
    }

    fn status_v2_nulls_count(conn: &Connection, event_id: &str) -> rusqlite::Result<u64> {
        let mut stmt = conn.prepare("SELECT COUNT(*) FROM event_attendance WHERE event_id=?1 AND status_v2 IS NULL");
        match stmt {
            Ok(mut s) => {
                let n: i64 = s.query_row(params![event_id], |r| r.get(0)).unwrap_or(0);
                Ok(n as u64)
            }
            Err(_) => Ok(0), // column likely missing; treat as 0
        }
    }

    pub fn status_v2_nulls(event_id: &str) -> Result<u64, String> {
        let conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        status_v2_nulls_count(&conn, event_id).map_err(|e| e.to_string())
    }

    #[derive(Debug, Default, serde::Serialize)]
    pub struct CommitOutcome {
        pub rowsImported: u64,
        pub rowsErrored: u64,
        pub duplicates: u64,
    }

    pub fn commit_csv_for_event(event_id: &str, csv_text: &str) -> Result<CommitOutcome, String> {
        let mut conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let tx = conn.transaction().map_err(|e| e.to_string())?;

        let mut outcome = CommitOutcome::default();
        let mut rdr = csv::ReaderBuilder::new().flexible(true).trim(csv::Trim::All).from_reader(csv_text.as_bytes());
        let headers = rdr.headers().map_err(|e| e.to_string())?.clone();
        let mut email_idx: Option<usize> = None;
        let mut name_idx: Option<usize> = None;
        let mut first_idx: Option<usize> = None;
        let mut last_idx: Option<usize> = None;
        let mut company_idx: Option<usize> = None;
        let mut status_idx: Option<usize> = None;
        for (i, h) in headers.iter().enumerate() {
            let key = h.to_lowercase();
            match key.as_str() {
                "email" => email_idx = Some(i),
                "name" => name_idx = Some(i),
                "firstname" | "first_name" | "first" => first_idx = Some(i),
                "lastname" | "last_name" | "last" => last_idx = Some(i),
                "company" => company_idx = Some(i),
                "status" => status_idx = Some(i),
                _ => {}
            }
        }

        for rec_res in rdr.records() {
            let rec = match rec_res { Ok(r) => r, Err(_) => { outcome.rowsErrored += 1; continue; } };
            let email = email_idx.and_then(|i| rec.get(i)).unwrap_or("").trim().to_lowercase();
            let name = name_idx.and_then(|i| rec.get(i)).unwrap_or("").trim().to_string();
            let first = first_idx.and_then(|i| rec.get(i)).unwrap_or("").trim().to_string();
            let last = last_idx.and_then(|i| rec.get(i)).unwrap_or("").trim().to_string();
            let company = company_idx.and_then(|i| rec.get(i)).unwrap_or("").trim().to_string();
            let status_raw = status_idx.and_then(|i| rec.get(i)).unwrap_or("");
            let status = normalize_status_str(status_raw).unwrap_or(crate::status::AttendeeStatus::Preregistered).as_str();

            if email.is_empty() && name.is_empty() && (first.is_empty() && last.is_empty()) {
                outcome.rowsErrored += 1; continue;
            }

            // Determine or create member by email
            let member_id = if !email.is_empty() {
                tx.query_row(
                    "SELECT id FROM members WHERE email = ?1",
                    params![email],
                    |row| row.get::<_, String>(0),
                ).optional().map_err(|e| e.to_string())?
                .unwrap_or_else(|| {
                    let id = Uuid::new_v4().to_string();
                    let (first_name, last_name) = if !first.is_empty() || !last.is_empty() {
                        (first.clone(), last.clone())
                    } else {
                        // split "Name" into first/last naive
                        if name.contains(' ') { let mut it = name.splitn(2, ' '); (it.next().unwrap().to_string(), it.next().unwrap_or("").to_string()) } else { (name.clone(), String::new()) }
                    };
                    tx.execute(
                        "INSERT INTO members (id,email,first_name,last_name,company) VALUES (?1,?2,?3,?4,?5)",
                        params![id, Some(email.as_str()), first_name, last_name, company],
                    ).unwrap();
                    id
                })
            } else {
                // No email: create a member with generated id
                let id = Uuid::new_v4().to_string();
                let (first_name, last_name) = if !first.is_empty() || !last.is_empty() {
                    (first.clone(), last.clone())
                } else {
                    if name.contains(' ') { let mut it = name.splitn(2, ' '); (it.next().unwrap().to_string(), it.next().unwrap_or("").to_string()) } else { (name.clone(), String::new()) }
                };
                tx.execute(
                    "INSERT INTO members (id,email,first_name,last_name,company) VALUES (?1,?2,?3,?4,?5)",
                    params![id, Option::<&str>::None, first_name, last_name, company],
                ).map_err(|e| e.to_string())?;
                id
            };

            // Create attendance if not exists
            let attendance_id = Uuid::new_v4().to_string();
            let res = tx.execute(
                "INSERT INTO event_attendance (id, member_id, event_id, status, source) VALUES (?1,?2,?3,?4,?5)",
                params![attendance_id, member_id, event_id, status, if email.is_empty() { "walkin" } else { "prereg" }],
            );
            match res {
                Ok(_) => {
                    outcome.rowsImported += 1;
                    // dual-write status_v2 if present
                    try_set_status_v2(&tx, &attendance_id, status);
                    // Audit log
                    let audit_id = Uuid::new_v4().to_string();
                    let _ = tx.execute(
                        "INSERT INTO status_audit_log (id, attendance_id, prior_status, new_status, reason, changed_by) VALUES (?1,?2,?3,?4,?5,?6)",
                        params![audit_id, attendance_id, Option::<&str>::None, status, Option::<&str>::None, "csv_import"],
                    );
                }
                Err(e) => {
                    let msg = e.to_string();
                    if msg.contains("UNIQUE") { outcome.duplicates += 1; /* already exists for event */ } else { outcome.rowsErrored += 1; }
                }
            }
        }

        tx.commit().map_err(|e| e.to_string())?;
        Ok(outcome)
    }

    pub fn update_status(
        attendance_id: &str,
        new_status_str: &str,
        event_in_progress: bool,
        has_manager_override: bool,
        reason: Option<&str>,
        changed_by: Option<&str>,
    ) -> Result<bool, String> {
        let mut conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let tx = conn.transaction().map_err(|e| e.to_string())?;

        // Fetch current status
        let (cur_status_txt, event_id): (String, String) = tx
            .query_row(
                "SELECT status, event_id FROM event_attendance WHERE id = ?1",
                params![attendance_id],
                |r| Ok((r.get(0)?, r.get(1)?)),
            )
            .map_err(|_| "attendance_not_found".to_string())?;

        let cur = AttendeeStatus::from_str(&cur_status_txt).ok_or_else(|| "invalid_current_status".to_string())?;
        let new_enum = normalize_status_str(new_status_str).ok_or_else(|| "invalid_new_status".to_string())?;

        let check = validate_status_transition(cur, new_enum, event_in_progress, has_manager_override);
        match check {
            TransitionCheck::Ok => {}
            TransitionCheck::NeedsReason => {
                if reason.unwrap_or("").trim().is_empty() {
                    return Err("reason_required".into());
                }
            }
            TransitionCheck::NeedsManagerOverride => {
                if !has_manager_override {
                    return Err("manager_override_required".into());
                }
            }
        }

        // Update status and checked_in_at if needed
        if matches!(new_enum, AttendeeStatus::Checkedin) {
            tx.execute(
                "UPDATE event_attendance SET status = ?1, checked_in_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP WHERE id = ?2",
                params![new_enum.as_str(), attendance_id],
            ).map_err(|e| e.to_string())?;
        } else {
            tx.execute(
                "UPDATE event_attendance SET status = ?1, updated_at = CURRENT_TIMESTAMP WHERE id = ?2",
                params![new_enum.as_str(), attendance_id],
            ).map_err(|e| e.to_string())?;
        }
        // dual-write status_v2 if present
        try_set_status_v2(&tx, attendance_id, new_enum.as_str());

        // Audit log
        let audit_id = Uuid::new_v4().to_string();
        tx.execute(
            "INSERT INTO status_audit_log (id, attendance_id, prior_status, new_status, reason, changed_by) VALUES (?1,?2,?3,?4,?5,?6)",
            params![audit_id, attendance_id, cur.as_str(), new_enum.as_str(), reason.unwrap_or("") , changed_by.unwrap_or("edp_update_status")],
        ).map_err(|e| e.to_string())?;

        tx.commit().map_err(|e| e.to_string())?;
        Ok(true)
    }

    #[derive(Debug, Default, serde::Serialize)]
    pub struct StatusCounts {
        pub preregistered: u64,
        pub walkin: u64,
        pub checkedin: u64,
        pub dna: u64,
    }

    pub fn counts_by_status(event_id: &str) -> Result<StatusCounts, String> {
        let conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let mut stmt = conn.prepare("SELECT status, COUNT(*) c FROM event_attendance WHERE event_id = ?1 GROUP BY status").map_err(|e| e.to_string())?;
        let mut counts = StatusCounts::default();
        let rows = stmt.query_map(params![event_id], |row| {
            let status: String = row.get(0)?;
            let c: u64 = row.get::<_, i64>(1)? as u64;
            Ok((status, c))
        }).map_err(|e| e.to_string())?;
        for r in rows { let (s, c) = r.map_err(|e| e.to_string())?; match s.as_str() { "preregistered" => counts.preregistered = c, "walkin" => counts.walkin = c, "checkedin" => counts.checkedin = c, "dna" => counts.dna = c, _ => {} } }
        Ok(counts)
    }

    pub fn process_auto_rollover(
        event_id: &str,
        event_end_epoch_s: i64,
        now_epoch_s: i64,
        grace_seconds: i64,
    ) -> Result<u64, String> {
        // Only proceed if end+grace <= now
        if now_epoch_s < event_end_epoch_s.saturating_add(grace_seconds) {
            return Ok(0);
        }
        let mut conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let tx = conn.transaction().map_err(|e| e.to_string())?;
        // Select affected attendance ids and their prior status for audit rows
        let mut sel = tx.prepare(
            "SELECT id, status FROM event_attendance WHERE event_id = ?1 AND status IN ('preregistered','walkin') AND checked_in_at IS NULL",
        ).map_err(|e| e.to_string())?;
        let rows = sel.query_map(params![event_id], |r| Ok((r.get::<_, String>(0)?, r.get::<_, String>(1)?))).map_err(|e| e.to_string())?;
        let mut affected: Vec<(String,String)> = Vec::new();
        for r in rows { affected.push(r.map_err(|e| e.to_string())?); }
        drop(sel);
        // Update statuses
        let updated = tx.execute(
            "UPDATE event_attendance SET status='dna', updated_at=CURRENT_TIMESTAMP WHERE event_id=?1 AND status IN ('preregistered','walkin') AND checked_in_at IS NULL",
            params![event_id],
        ).map_err(|e| e.to_string())? as u64;
        // Audit insert
        for (att_id, prior) in affected {
            let audit_id = Uuid::new_v4().to_string();
            let _ = tx.execute(
                "INSERT INTO status_audit_log (id, attendance_id, prior_status, new_status, reason, changed_by) VALUES (?1,?2,?3,?4,?5,?6)",
                params![audit_id, att_id, prior, "dna", "grace period expired", "auto_rollover"],
            );
        }
        tx.commit().map_err(|e| e.to_string())?;
        Ok(updated)
    }

    /// Backfill status_v2 from legacy `status` for a specific event where NULL.
    pub fn backfill_status_v2(event_id: &str) -> Result<u64, String> {
        let conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        // Attempt to add column if not present (no-op if exists)
        let _ = conn.execute(
            "ALTER TABLE event_attendance ADD COLUMN status_v2 TEXT CHECK (status_v2 IN ('preregistered','walkin','checkedin','dna'))",
            params![],
        );
        // Use CASE mapping to normalize common legacy values; otherwise copy status
        let sql = r#"
            UPDATE event_attendance
            SET status_v2 = (
              CASE
                WHEN status IN ('checkedin','attended','present') THEN 'checkedin'
                WHEN status IN ('dna','noshow','no_show') THEN 'dna'
                WHEN status IN ('walkin','walk_in') THEN 'walkin'
                ELSE 'preregistered'
              END
            )
            WHERE event_id = ?1 AND status_v2 IS NULL;
        "#;
        let changed = conn.execute(sql, params![event_id]).map_err(|e| e.to_string())? as u64;
        Ok(changed)
    }

    #[derive(serde::Serialize)]
    pub struct AttendeeRow {
        pub attendeeId: String,
        pub memberId: String,
        pub eventId: String,
        pub name: String,
        pub email: Option<String>,
        pub company: Option<String>,
        pub status: String,
        pub checkedInAt: Option<String>,
    }

    pub fn list_attendance(event_id: &str) -> Result<Vec<AttendeeRow>, String> {
        let conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let mut stmt = conn.prepare(
            "SELECT ea.id as attendeeId, ea.member_id as memberId, ea.event_id as eventId,
                    m.first_name, m.last_name, m.email, m.company,
                    ea.status, ea.checked_in_at
             FROM event_attendance ea JOIN members m ON m.id = ea.member_id
             WHERE ea.event_id = ?1 ORDER BY m.last_name, m.first_name",
        ).map_err(|e| e.to_string())?;
        let rows = stmt.query_map(params![event_id], |row| {
            let attendee_id: String = row.get("attendeeId")?;
            let member_id: String = row.get("memberId")?;
            let event_id: String = row.get("eventId")?;
            let first: String = row.get("first_name")?;
            let last: String = row.get("last_name")?;
            let name = if last.is_empty() { first.clone() } else { format!("{} {}", first, last) };
            let email: Option<String> = row.get("email").ok();
            let company: Option<String> = row.get("company").ok();
            let status: String = row.get("status")?;
            let checked_in_at: Option<String> = row.get("checked_in_at").ok();
            Ok(AttendeeRow { attendeeId: attendee_id, memberId: member_id, eventId: event_id, name, email, company, status, checkedInAt: checked_in_at })
        }).map_err(|e| e.to_string())?;
        let mut out = Vec::new();
        for r in rows { out.push(r.map_err(|e| e.to_string())?); }
        Ok(out)
    }

    pub fn remove_attendance(attendance_id: &str, reason: Option<&str>, changed_by: Option<&str>) -> Result<bool, String> {
        let mut conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let tx = conn.transaction().map_err(|e| e.to_string())?;
        // get event for audit
        let old_status: String = tx.query_row(
            "SELECT status FROM event_attendance WHERE id = ?1",
            params![attendance_id],
            |r| r.get(0),
        ).map_err(|_| "attendance_not_found".to_string())?;
        let deleted = tx.execute("DELETE FROM event_attendance WHERE id = ?1", params![attendance_id]).map_err(|e| e.to_string())?;
        if deleted > 0 {
            let audit_id = Uuid::new_v4().to_string();
            let _ = tx.execute(
                "INSERT INTO status_audit_log (id, attendance_id, prior_status, new_status, reason, changed_by) VALUES (?1,?2,?3,?4,?5,?6)",
                params![audit_id, attendance_id, old_status, "removed", reason.unwrap_or("removed"), changed_by.unwrap_or("remove_attendance")],
            );
        }
        tx.commit().map_err(|e| e.to_string())?;
        Ok(deleted > 0)
    }

    #[derive(serde::Serialize)]
    pub struct MemberRow { pub id: String, pub email: Option<String>, pub firstName: String, pub lastName: String, pub company: Option<String> }

    pub fn search_members(query: &str, limit: i64) -> Result<Vec<MemberRow>, String> {
        let conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let like = format!("%{}%", query.to_lowercase());
        let mut stmt = conn.prepare(
            "SELECT id, email, first_name, last_name, company FROM members WHERE 
             LOWER(COALESCE(email,'')) LIKE ?1 OR LOWER(first_name) LIKE ?1 OR LOWER(last_name) LIKE ?1 ORDER BY last_name, first_name LIMIT ?2",
        ).map_err(|e| e.to_string())?;
        let rows = stmt.query_map(params![like, limit], |r| {
            Ok(MemberRow{ id: r.get(0)?, email: r.get(1).ok(), firstName: r.get(2)?, lastName: r.get(3)?, company: r.get(4).ok() })
        }).map_err(|e| e.to_string())?;
        let mut out = Vec::new(); for r in rows { out.push(r.map_err(|e| e.to_string())?); }
        Ok(out)
    }

    #[derive(serde::Serialize)]
    pub struct WalkinResult { pub attendanceId: String, pub memberId: String, pub eventId: String, pub status: String }

    pub fn create_walkin(event_id: &str, name: &str, email: Option<&str>, phone: Option<&str>, company: Option<&str>, immediate_checkin: bool, changed_by: Option<&str>) -> Result<WalkinResult, String> {
        if name.trim().is_empty() && email.unwrap_or("").trim().is_empty() { return Err("name_or_email_required".into()); }
        let mut conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let tx = conn.transaction().map_err(|e| e.to_string())?;
        // find or create member by email
        let mut member_id: Option<String> = None;
        if let Some(em) = email { if !em.trim().is_empty() {
            member_id = tx.query_row("SELECT id FROM members WHERE email=?1", params![em.to_lowercase()], |r| r.get::<_, String>(0)).optional().map_err(|e| e.to_string())?;
        }}
        let member_id = match member_id {
            Some(id) => id,
            None => {
                let id = Uuid::new_v4().to_string();
                // naive split
                let (first, last) = if name.contains(' ') { let mut it = name.splitn(2, ' '); (it.next().unwrap().to_string(), it.next().unwrap_or("").to_string()) } else { (name.to_string(), String::new()) };
                tx.execute(
                    "INSERT INTO members (id,email,first_name,last_name,phone,company) VALUES (?1,?2,?3,?4,?5,?6)",
                    params![id, email.map(|e| e.to_lowercase()), first, last, phone.unwrap_or(""), company.unwrap_or("")],
                ).map_err(|e| e.to_string())?;
                id
            }
        };
        let attendance_id = Uuid::new_v4().to_string();
        let status = if immediate_checkin { "checkedin" } else { "walkin" };
        tx.execute(
            "INSERT INTO event_attendance (id, member_id, event_id, status, source, checked_in_at) VALUES (?1,?2,?3,?4,?5,?6)",
            params![attendance_id, member_id, event_id, status, "walkin", if immediate_checkin { Some("now") } else { None::<&str> }],
        ).map_err(|e| e.to_string())?;
        // dual-write status_v2 if present
        try_set_status_v2(&tx, &attendance_id, status);
        // audit: new attendance created; prior_status is NULL, new_status is walkin/checkedin
        let audit_id = Uuid::new_v4().to_string();
        let _ = tx.execute(
            "INSERT INTO status_audit_log (id, attendance_id, prior_status, new_status, reason, changed_by) VALUES (?1,?2,?3,?4,?5,?6)",
            params![audit_id, attendance_id, Option::<&str>::None, status, "walkin", changed_by.unwrap_or("walkin")],
        );
        tx.commit().map_err(|e| e.to_string())?;
        Ok(WalkinResult{ attendanceId: attendance_id, memberId: member_id, eventId: event_id.to_string(), status: status.to_string() })
    }

    pub fn merge_members(primary_id: &str, duplicate_id: &str) -> Result<u64, String> {
        if primary_id == duplicate_id { return Ok(0); }
        let mut conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let tx = conn.transaction().map_err(|e| e.to_string())?;
        // collect attendance rows of duplicate
        let mut stmt = tx.prepare("SELECT id FROM event_attendance WHERE member_id=?1").map_err(|e| e.to_string())?;
        let rows = stmt.query_map(params![duplicate_id], |r| r.get::<_, String>(0)).map_err(|e| e.to_string())?;
        let mut moved: u64 = 0;
        for r in rows {
            let att_id = r.map_err(|e| e.to_string())?;
            // attempt update to primary; if UNIQUE constraint, delete duplicate row
            match tx.execute("UPDATE event_attendance SET member_id=?1 WHERE id=?2", params![primary_id, att_id]) {
                Ok(1) => moved += 1,
                Ok(_) => {},
                Err(e) => {
                    let msg = e.to_string();
                    if msg.contains("UNIQUE") {
                        let _ = tx.execute("DELETE FROM event_attendance WHERE id=?1", params![att_id]);
                    } else { return Err(msg); }
                }
            }
        }
        // delete duplicate member
        let _ = tx.execute("DELETE FROM members WHERE id=?1", params![duplicate_id]);
        // log merge
        let merge_id = Uuid::new_v4().to_string();
        let _ = tx.execute("INSERT INTO member_merge_log (id, from_member_id, to_member_id) VALUES (?1,?2,?3)", params![merge_id, duplicate_id, primary_id]);
        drop(stmt);
        tx.commit().map_err(|e| e.to_string())?;
        Ok(moved)
    }

    // Events API
    #[derive(serde::Serialize)]
    pub struct EventRow { pub id: String, pub name: String, pub startsAt: String, pub endsAt: String, pub location: Option<String>, pub capacity: Option<i64>, pub status: Option<String>, pub timezone: Option<String>, pub description: Option<String> }

    pub fn create_event(id: Option<&str>, name: &str, starts_at: &str, ends_at: &str, location: Option<&str>, capacity: Option<i64>, status: Option<&str>, timezone: Option<&str>, description: Option<&str>) -> Result<String, String> {
        if name.trim().is_empty() { return Err("name_required".into()); }
        let conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let id_str = id.map(|s| s.to_string()).unwrap_or_else(|| Uuid::new_v4().to_string());
        conn.execute(
            "INSERT INTO events (id,name,starts_at,ends_at,location,capacity,status,timezone,description) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9)",
            params![id_str, name, starts_at, ends_at, location.unwrap_or(""), capacity.unwrap_or(0), status.unwrap_or("active"), timezone.unwrap_or("UTC"), description.unwrap_or("")],
        ).map_err(|e| e.to_string())?;
        Ok(id_str)
    }

    pub fn update_event(id: &str, name: Option<&str>, starts_at: Option<&str>, ends_at: Option<&str>, location: Option<&str>, capacity: Option<i64>, status: Option<&str>, timezone: Option<&str>, description: Option<&str>) -> Result<bool, String> {
        let conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        // Build dynamic update with COALESCE pattern
        let mut stmt = conn.prepare(
            "UPDATE events SET name=COALESCE(?2,name), starts_at=COALESCE(?3,starts_at), ends_at=COALESCE(?4,ends_at), location=COALESCE(?5,location), capacity=COALESCE(?6,capacity), status=COALESCE(?7,status), timezone=COALESCE(?8,timezone), description=COALESCE(?9,description) WHERE id=?1"
        ).map_err(|e| e.to_string())?;
        let changed = stmt.execute(params![id, name, starts_at, ends_at, location, capacity, status, timezone, description]).map_err(|e| e.to_string())?;
        Ok(changed > 0)
    }

    pub fn list_events(limit: i64, offset: i64) -> Result<Vec<EventRow>, String> {
        let conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let mut stmt = conn.prepare(
            "SELECT id,name,starts_at,ends_at,location,capacity,status,timezone,description FROM events ORDER BY starts_at DESC LIMIT ?1 OFFSET ?2"
        ).map_err(|e| e.to_string())?;
        let rows = stmt.query_map(params![limit, offset], |r| {
            Ok(EventRow{ id: r.get(0)?, name: r.get(1)?, startsAt: r.get(2)?, endsAt: r.get(3)?, location: r.get(4).ok(), capacity: r.get(5).ok(), status: r.get(6).ok(), timezone: r.get(7).ok(), description: r.get(8).ok() })
        }).map_err(|e| e.to_string())?;
        let mut out = Vec::new(); for r in rows { out.push(r.map_err(|e| e.to_string())?); }
        Ok(out)
    }

    pub fn delete_event(event_id: &str) -> Result<u64, String> {
        let mut conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let tx = conn.transaction().map_err(|e| e.to_string())?;
        let _ = tx.execute("DELETE FROM event_attendance WHERE event_id=?1", params![event_id]);
        let deleted = tx.execute("DELETE FROM events WHERE id=?1", params![event_id]).map_err(|e| e.to_string())? as u64;
        tx.commit().map_err(|e| e.to_string())?;
        Ok(deleted)
    }

    #[derive(serde::Serialize)]
    pub struct MemberProfile { pub id: String, pub email: Option<String>, pub firstName: String, pub lastName: String, pub company: Option<String>, pub events: Vec<(String,String,String)> }

    pub fn member_profile(member_id: &str) -> Result<MemberProfile, String> {
        let conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let mut stmt = conn.prepare("SELECT id,email,first_name,last_name,company FROM members WHERE id=?1").map_err(|e| e.to_string())?;
        let (id,email,first,last,company):(String,Option<String>,String,String,Option<String>) = stmt.query_row(params![member_id], |r| Ok((r.get(0)?, r.get(1).ok(), r.get(2)?, r.get(3)?, r.get(4).ok()))).map_err(|_| "member_not_found".to_string())?;
        let mut evstmt = conn.prepare("SELECT event_id,status,COALESCE(checked_in_at,'') FROM event_attendance WHERE member_id=?1 ORDER BY created_at DESC").map_err(|e| e.to_string())?;
        let rows = evstmt.query_map(params![member_id], |r| Ok((r.get::<_,String>(0)?, r.get::<_,String>(1)?, r.get::<_,String>(2)?))).map_err(|e| e.to_string())?;
        let mut events = Vec::new(); for r in rows { events.push(r.map_err(|e| e.to_string())?); }
        Ok(MemberProfile{ id, email, firstName:first, lastName:last, company, events })
    }

    /// Create a member (global directory). If email exists, returns existing id.
    pub fn create_member(
        email: Option<&str>,
        first_name: &str,
        last_name: &str,
        phone: Option<&str>,
        company: Option<&str>,
        tags: Option<&str>,
        notes: Option<&str>,
    ) -> Result<String, String> {
        if first_name.trim().is_empty() && email.unwrap_or("").trim().is_empty() {
            return Err("first_or_email_required".into());
        }
        let conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        // If email provided and exists, return existing id
        if let Some(e) = email.map(|s| s.to_lowercase()) {
            if !e.is_empty() {
                if let Some(id) = conn
                    .query_row("SELECT id FROM members WHERE email=?1", params![e], |r| r.get::<_, String>(0))
                    .optional()
                    .map_err(|er| er.to_string())?
                {
                    return Ok(id);
                }
            }
        }
        let id = uuid::Uuid::new_v4().to_string();
        conn.execute(
            "INSERT INTO members (id,email,first_name,last_name,phone,company,tags,notes) VALUES (?1,?2,?3,?4,?5,?6,?7,?8)",
            params![
                id,
                email.map(|s| s.to_lowercase()),
                first_name,
                last_name,
                phone.unwrap_or(""),
                company.unwrap_or(""),
                tags.unwrap_or(""),
                notes.unwrap_or("")
            ],
        )
        .map_err(|e| e.to_string())?;
        Ok(id)
    }

    /// Update member (global). Any NULL parameter leaves field unchanged.
    pub fn update_member(
        id: &str,
        email: Option<&str>,
        first_name: Option<&str>,
        last_name: Option<&str>,
        phone: Option<&str>,
        company: Option<&str>,
        tags: Option<&str>,
        notes: Option<&str>,
    ) -> Result<bool, String> {
        let conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let mut stmt = conn.prepare(
            "UPDATE members SET \
             email=COALESCE(?2,email), \
             first_name=COALESCE(?3,first_name), \
             last_name=COALESCE(?4,last_name), \
             phone=COALESCE(?5,phone), \
             company=COALESCE(?6,company), \
             tags=COALESCE(?7,tags), \
             notes=COALESCE(?8,notes) \
             WHERE id=?1",
        ).map_err(|e| e.to_string())?;
        let changed = stmt.execute(params![id, email, first_name, last_name, phone, company, tags, notes]).map_err(|e| e.to_string())?;
        Ok(changed > 0)
    }

    pub fn export_json_for_event(event_id: &str) -> Result<serde_json::Value, String> {
        let rows = list_attendance(event_id)?;
        Ok(serde_json::to_value(rows).map_err(|e| e.to_string())?)
    }

    pub fn export_csv_for_event(event_id: &str) -> Result<String, String> {
        let rows = list_attendance(event_id)?;
        let mut wtr = csv::WriterBuilder::new().from_writer(vec![]);
        wtr.write_record(["attendeeId","memberId","eventId","name","email","company","status","checkedInAt"]).map_err(|e| e.to_string())?;
        for r in rows {
            wtr.write_record([
                r.attendeeId,
                r.memberId,
                r.eventId,
                r.name,
                r.email.unwrap_or_default(),
                r.company.unwrap_or_default(),
                r.status,
                r.checkedInAt.unwrap_or_default(),
            ]).map_err(|e| e.to_string())?;
        }
        let data = wtr.into_inner().map_err(|e| e.to_string())?;
        String::from_utf8(data).map_err(|e| e.to_string())
    }

    #[derive(serde::Serialize)]
    pub struct AuditRow { pub id:String, pub attendanceId:String, pub priorStatus: Option<String>, pub newStatus:String, pub reason: Option<String>, pub changedBy: Option<String>, pub changedAt:String }

    pub fn list_status_audit(event_id: Option<&str>, attendance_id: Option<&str>, limit: i64) -> Result<Vec<AuditRow>, String> {
        let conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let mut out = Vec::new();
        if let Some(eid) = event_id {
            let mut stmt = conn.prepare("SELECT id, attendance_id, prior_status, new_status, reason, changed_by, changed_at FROM status_audit_log WHERE attendance_id IN (SELECT id FROM event_attendance WHERE event_id=?1) ORDER BY changed_at DESC LIMIT ?2").map_err(|e| e.to_string())?;
            let rows = stmt.query_map(params![eid, limit], |r| Ok(AuditRow{ id:r.get(0)?, attendanceId:r.get(1)?, priorStatus:r.get(2).ok(), newStatus:r.get(3)?, reason:r.get(4).ok(), changedBy:r.get(5).ok(), changedAt:r.get(6)?})).map_err(|e| e.to_string())?;
            for r in rows { out.push(r.map_err(|e| e.to_string())?); }
        } else if let Some(aid) = attendance_id {
            let mut stmt = conn.prepare("SELECT id, attendance_id, prior_status, new_status, reason, changed_by, changed_at FROM status_audit_log WHERE attendance_id=?1 ORDER BY changed_at DESC LIMIT ?2").map_err(|e| e.to_string())?;
            let rows = stmt.query_map(params![aid, limit], |r| Ok(AuditRow{ id:r.get(0)?, attendanceId:r.get(1)?, priorStatus:r.get(2).ok(), newStatus:r.get(3)?, reason:r.get(4).ok(), changedBy:r.get(5).ok(), changedAt:r.get(6)?})).map_err(|e| e.to_string())?;
            for r in rows { out.push(r.map_err(|e| e.to_string())?); }
        } else {
            let mut stmt = conn.prepare("SELECT id, attendance_id, prior_status, new_status, reason, changed_by, changed_at FROM status_audit_log ORDER BY changed_at DESC LIMIT ?1").map_err(|e| e.to_string())?;
            let rows = stmt.query_map(params![limit], |r| Ok(AuditRow{ id:r.get(0)?, attendanceId:r.get(1)?, priorStatus:r.get(2).ok(), newStatus:r.get(3)?, reason:r.get(4).ok(), changedBy:r.get(5).ok(), changedAt:r.get(6)?})).map_err(|e| e.to_string())?;
            for r in rows { out.push(r.map_err(|e| e.to_string())?); }
        }
        Ok(out)
    }

    pub fn bulk_status_update(event_id: &str, attendee_ids: &[&str], new_status_str: &str, event_in_progress: bool, has_manager_override: bool, reason: Option<&str>, changed_by: Option<&str>) -> Result<u64, String> {
        let mut conn = open_conn().map_err(|e| e.to_string())?;
        apply_schema(&conn).map_err(|e| e.to_string())?;
        let tx = conn.transaction().map_err(|e| e.to_string())?;
        let new_enum = normalize_status_str(new_status_str).ok_or_else(|| "invalid_new_status".to_string())?;
        let mut updated = 0u64;
        for aid in attendee_ids {
            // Fetch current
            if let Ok((cur_txt, eid)) = tx.query_row("SELECT status,event_id FROM event_attendance WHERE id=?1", params![aid], |r| Ok((r.get::<_,String>(0)?, r.get::<_,String>(1)?))) {
                if eid != event_id { continue; }
                let cur = AttendeeStatus::from_str(&cur_txt).unwrap_or(AttendeeStatus::Preregistered);
                let check = validate_status_transition(cur, new_enum, event_in_progress, has_manager_override);
                match check {
                    TransitionCheck::NeedsReason if reason.unwrap_or("").is_empty() => continue,
                    TransitionCheck::NeedsManagerOverride if !has_manager_override => continue,
                    _ => {}
                }
                let _ = tx.execute("UPDATE event_attendance SET status=?1, updated_at=CURRENT_TIMESTAMP WHERE id=?2", params![new_enum.as_str(), aid]);
                let audit_id = Uuid::new_v4().to_string();
                let _ = tx.execute("INSERT INTO status_audit_log (id, attendance_id, prior_status, new_status, reason, changed_by) VALUES (?1,?2,?3,?4,?5,?6)", params![audit_id, aid, cur.as_str(), new_enum.as_str(), reason.unwrap_or(""), changed_by.unwrap_or("bulk")]);
                updated += 1;
            }
        }
        tx.commit().map_err(|e| e.to_string())?;
        Ok(updated)
    }
}

pub mod analytics_store {
    use once_cell::sync::OnceCell;
    use std::fs::{OpenOptions};
    use std::io::Write;
    use std::path::PathBuf;

    static ANALYTICS_PATH: OnceCell<PathBuf> = OnceCell::new();

    pub fn set_path(path: &str) -> bool {
        let pb = PathBuf::from(path);
        ANALYTICS_PATH.set(pb).is_ok()
    }

    pub fn append(json_line: &str) -> std::io::Result<()> {
        if let Some(p) = ANALYTICS_PATH.get() {
            let mut file = OpenOptions::new().create(true).append(true).open(p)?;
            file.write_all(json_line.as_bytes())?;
            file.write_all(b"\n")?;
        }
        Ok(())
    }
}

pub mod analytics {
    /// Validate analytics event JSON according to rules in docs/ANALYTICS.md
    pub fn validate_event_json(txt: &str) -> bool {
        let Ok(val) = serde_json::from_str::<serde_json::Value>(txt) else { return false };
        let Some(name) = val.get("name").and_then(|v| v.as_str()) else { return false };
        if !is_allowed_event(name) { return false; }
        if !val.get("timestamp").and_then(|v| v.as_str()).is_some() { return false; }
        if let Some(payload) = val.get("payload") {
            if payload.get("emails").is_some() || payload.get("names").is_some() { return false; }
        }
        if let Some(ctx) = val.get("context") {
            if ctx.get("emails").is_some() || ctx.get("names").is_some() { return false; }
        }
        true
    }

    fn is_allowed_event(name: &str) -> bool {
        matches!(name,
            "attendee_panel_open" |
            "attendee_contact_save" |
            "attendee_participation_save" |
            "attendee_status_change" |
            "walk_in_create" |
            "csv_import_preview" |
            "csv_import_commit" |
            "csv_export" |
            "member_profile_open" |
            "open_in_event"
        )
    }
}

#[cfg(feature = "ffi")]
pub mod ffi {
    use super::status::AttendeeStatus;
    use super::validate::TransitionCheck;
    use std::os::raw::{c_char, c_int};
    use std::ffi::{CString, CStr};

    #[no_mangle]
    pub extern "C" fn edp_status_from_str(ptr: *const c_char) -> c_int {
        if ptr.is_null() { return -1; }
        let cstr = unsafe { std::ffi::CStr::from_ptr(ptr) };
        match cstr.to_str().ok().and_then(AttendeeStatus::from_str) {
            Some(AttendeeStatus::Preregistered) => 0,
            Some(AttendeeStatus::Walkin) => 1,
            Some(AttendeeStatus::Checkedin) => 2,
            Some(AttendeeStatus::Dna) => 3,
            None => -1,
        }
    }

    #[no_mangle]
    pub extern "C" fn edp_status_to_str(code: c_int) -> *const c_char {
        match code {
            0 => b"preregistered\0".as_ptr() as *const c_char,
            1 => b"walkin\0".as_ptr() as *const c_char,
            2 => b"checkedin\0".as_ptr() as *const c_char,
            3 => b"dna\0".as_ptr() as *const c_char,
            _ => std::ptr::null(),
        }
    }

    #[no_mangle]
    pub extern "C" fn edp_status_label(code: c_int) -> *const c_char {
        match code {
            0 => b"Pre-Registered\0".as_ptr() as *const c_char,
            1 => b"Walk-in\0".as_ptr() as *const c_char,
            2 => b"Checked-In\0".as_ptr() as *const c_char,
            3 => b"Did Not Attend\0".as_ptr() as *const c_char,
            _ => std::ptr::null(),
        }
    }

    #[no_mangle]
    pub extern "C" fn edp_validate_transition(
        current: c_int,
        new_status: c_int,
        event_in_progress: bool,
        has_manager_override: bool,
    ) -> c_int {
        let cur = match current {
            0 => AttendeeStatus::Preregistered,
            1 => AttendeeStatus::Walkin,
            2 => AttendeeStatus::Checkedin,
            3 => AttendeeStatus::Dna,
            _ => AttendeeStatus::Preregistered,
        };
        let new = match new_status {
            0 => AttendeeStatus::Preregistered,
            1 => AttendeeStatus::Walkin,
            2 => AttendeeStatus::Checkedin,
            3 => AttendeeStatus::Dna,
            _ => AttendeeStatus::Preregistered,
        };
        match super::validate::validate_status_transition(cur, new, event_in_progress, has_manager_override) {
            TransitionCheck::Ok => 0,
            TransitionCheck::NeedsReason => 1,
            TransitionCheck::NeedsManagerOverride => 2,
        }
    }

    /// Normalize any free-form status string into canonical code integer.
    /// Returns -1 if unknown.
    #[no_mangle]
    pub extern "C" fn edp_normalize_status(ptr: *const c_char) -> c_int {
        if ptr.is_null() { return -1; }
        let cstr = unsafe { std::ffi::CStr::from_ptr(ptr) };
        match cstr.to_str().ok().and_then(|s| crate::util::normalize_status_str(s)) {
            Some(AttendeeStatus::Preregistered) => 0,
            Some(AttendeeStatus::Walkin) => 1,
            Some(AttendeeStatus::Checkedin) => 2,
            Some(AttendeeStatus::Dna) => 3,
            None => -1,
        }
    }

    /// Return 1 if rollover due, else 0.
    #[no_mangle]
    pub extern "C" fn edp_auto_rollover_due(event_end_epoch_s: i64, grace_seconds: i64, now_epoch_s: i64) -> c_int {
        if crate::util::auto_rollover_due(event_end_epoch_s, grace_seconds, now_epoch_s) { 1 } else { 0 }
    }
}

#[cfg(feature = "ffi")]
pub mod ffi_extras {
    use std::os::raw::{c_char, c_int};
    use std::ffi::{CString, CStr};
    use std::cell::RefCell;

    thread_local! {
        static LAST_ERROR: RefCell<Option<String>> = RefCell::new(None);
    }

    fn set_last_error(msg: String) {
        LAST_ERROR.with(|e| *e.borrow_mut() = Some(msg));
    }

    fn take_last_error() -> Option<String> {
        LAST_ERROR.with(|e| e.borrow_mut().take())
    }

    /// Returns the core/FFI version string (static, do not free)
    #[no_mangle]
    pub extern "C" fn edp_core_version() -> *const c_char {
        concat!("eventdesk_core ", env!("CARGO_PKG_VERSION"), " (ffi)\0").as_ptr() as *const c_char
    }
    
    /// Validate whether the given status string is a valid canonical SSOT status.
    /// Returns 1 if valid, else 0.
    #[no_mangle]
    pub extern "C" fn edp_validate_status_code(ptr: *const c_char) -> c_int {
        if ptr.is_null() { return 0; }
        let cstr = unsafe { CStr::from_ptr(ptr) };
        match cstr.to_str().ok().and_then(|s| crate::status::AttendeeStatus::from_str(s)) {
            Some(_) => 1,
            None => 0,
        }
    }

    /// Return number of SSOT status codes (static).
    #[no_mangle]
    pub extern "C" fn edp_ssot_status_count() -> c_int {
        4
    }

    /// Return canonical SSOT status code string at index or NULL.
    /// Returned pointer is static; do not free.
    #[no_mangle]
    pub extern "C" fn edp_ssot_status_code_at(idx: c_int) -> *const c_char {
        match idx {
            0 => b"preregistered\0".as_ptr() as *const c_char,
            1 => b"walkin\0".as_ptr() as *const c_char,
            2 => b"checkedin\0".as_ptr() as *const c_char,
            3 => b"dna\0".as_ptr() as *const c_char,
            _ => std::ptr::null(),
        }
    }
    /// Preview CSV (UTF-8 text) and return JSON string (heap-allocated).
    /// Caller must free with edp_free_cstr.
    #[no_mangle]
    pub extern "C" fn edp_csv_preview_utf8(csv_text_ptr: *const c_char) -> *mut c_char {
        if csv_text_ptr.is_null() { return std::ptr::null_mut(); }
        let csv_text = unsafe { CStr::from_ptr(csv_text_ptr) };
        let csv_str = match csv_text.to_str() { Ok(s) => s, Err(_) => return std::ptr::null_mut() };
        match crate::csvops::preview_csv_text(csv_str) {
            Ok(preview) => match serde_json::to_string(&preview) {
                Ok(s) => CString::new(s).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()),
                Err(_) => std::ptr::null_mut(),
            },
            Err(e) => { set_last_error(format!("csv_preview_failed: {}", e)); std::ptr::null_mut() },
        }
    }

    /// Free C string allocated by this library
    #[no_mangle]
    pub extern "C" fn edp_free_cstr(ptr: *mut c_char) {
        if ptr.is_null() { return; }
        unsafe { let _ = CString::from_raw(ptr); }
    }

    /// Validate analytics event JSON against schema rules; returns 1 if valid.
    #[no_mangle]
    pub extern "C" fn edp_analytics_validate(json_ptr: *const c_char) -> c_int {
        if json_ptr.is_null() { return 0; }
        let s = unsafe { CStr::from_ptr(json_ptr) };
        let Ok(txt) = s.to_str() else { return 0 };
        if crate::analytics::validate_event_json(txt) { 1 } else { 0 }
    }

    /// Validate then no-op emit; returns 1 if accepted.
    #[no_mangle]
    pub extern "C" fn edp_analytics_emit(json_ptr: *const c_char) -> c_int {
        if unsafe { super::ffi_extras::edp_analytics_validate(json_ptr) } == 0 { return 0; }
        // If analytics path set, append to file
        if !json_ptr.is_null() {
            let s = unsafe { CStr::from_ptr(json_ptr) };
            if let Ok(txt) = s.to_str() { let _ = crate::analytics_store::append(txt); }
        }
        1
    }

    /// Configure file-backed analytics queue path. Returns 1 if set, else 0.
    #[no_mangle]
    pub extern "C" fn edp_set_analytics_path(path_ptr: *const c_char) -> c_int {
        if path_ptr.is_null() { return 0; }
        let s = unsafe { CStr::from_ptr(path_ptr) };
        match crate::analytics_store::set_path(s.to_str().unwrap_or("") ) { true => 1, false => 0 }
    }

    /// Commit CSV preview (JSON from edp_csv_preview_utf8). Stub implementation:
    /// rowsImported = totals.valid, rowsErrored = totals.errors
    #[no_mangle]
    pub extern "C" fn edp_csv_commit_preview_json(preview_json_ptr: *const c_char) -> *mut c_char {
        if preview_json_ptr.is_null() { return std::ptr::null_mut(); }
        let s = unsafe { CStr::from_ptr(preview_json_ptr) };
        let Ok(txt) = s.to_str() else { return std::ptr::null_mut() };
        let Ok(val) = serde_json::from_str::<serde_json::Value>(txt) else { set_last_error("csv_commit_preview_invalid_json".to_string()); return std::ptr::null_mut() };
        let totals = match val.get("totals") { Some(t) => t, None => return std::ptr::null_mut() };
        let imported = totals.get("valid").and_then(|v| v.as_u64()).unwrap_or(0);
        let errored = totals.get("errors").and_then(|v| v.as_u64()).unwrap_or(0);
        let out = serde_json::json!({
            "rowsImported": imported,
            "rowsErrored": errored
        });
        let Ok(s) = serde_json::to_string(&out) else { set_last_error("csv_commit_preview_encode_failed".to_string()); return std::ptr::null_mut() };
        CString::new(s).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut())
    }

    /// Set DB path for commit operations. Returns 1 if set, else 0.
    #[no_mangle]
    pub extern "C" fn edp_set_db_path(path_ptr: *const c_char) -> c_int {
        if path_ptr.is_null() { return 0; }
        let s = unsafe { CStr::from_ptr(path_ptr) };
        match crate::db::set_db_path(s.to_str().unwrap_or("") ) { true => 1, false => 0 }
    }

    /// Commit CSV text for a given event (DB-backed). Returns JSON outcome {rowsImported, rowsErrored, duplicates}.
    #[no_mangle]
    pub extern "C" fn edp_csv_commit_for_event(event_id_ptr: *const c_char, csv_text_ptr: *const c_char) -> *mut c_char {
        if event_id_ptr.is_null() || csv_text_ptr.is_null() { return std::ptr::null_mut(); }
        let event_id = unsafe { CStr::from_ptr(event_id_ptr) };
        let csv_text = unsafe { CStr::from_ptr(csv_text_ptr) };
        let eid = match event_id.to_str() { Ok(s) => s, Err(_) => return std::ptr::null_mut() };
        let txt = match csv_text.to_str() { Ok(s) => s, Err(_) => return std::ptr::null_mut() };
        match crate::db::commit_csv_for_event(eid, txt) {
            Ok(outcome) => {
                match serde_json::to_string(&outcome) {
                    Ok(js) => CString::new(js).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()),
                    Err(_) => { set_last_error("csv_commit_encode_failed".to_string()); std::ptr::null_mut() },
                }
            }
            Err(e) => { set_last_error(format!("csv_commit_failed: {}", e)); std::ptr::null_mut() },
        }
    }

    /// Export CSV for an event. Returns heap CSV string which must be freed with edp_free_cstr.
    #[no_mangle]
    pub extern "C" fn edp_csv_export_for_event(event_id_ptr: *const c_char) -> *mut c_char {
        if event_id_ptr.is_null() { return std::ptr::null_mut(); }
        let event_id = unsafe { CStr::from_ptr(event_id_ptr) };
        let eid = match event_id.to_str() { Ok(s) => s, Err(_) => return std::ptr::null_mut() };
        match crate::db::export_csv_for_event(eid) {
            Ok(csv) => CString::new(csv).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()),
            Err(e) => { set_last_error(format!("csv_export_failed: {}", e)); std::ptr::null_mut() }
        }
    }

    /// Get counts by status for an event. Returns JSON {preregistered,walkin,checkedin,dna}
    #[no_mangle]
    pub extern "C" fn edp_counts_by_status(event_id_ptr: *const c_char) -> *mut c_char {
        if event_id_ptr.is_null() { return std::ptr::null_mut(); }
        let event_id = unsafe { CStr::from_ptr(event_id_ptr) };
        let eid = match event_id.to_str() { Ok(s) => s, Err(_) => return std::ptr::null_mut() };
        match crate::db::counts_by_status(eid) {
            Ok(c) => match serde_json::to_string(&c) { Ok(js) => CString::new(js).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()), Err(_) => std::ptr::null_mut() },
            Err(_) => std::ptr::null_mut(),
        }
    }

    /// Process auto-rollover: mark preregistered/walkin to dna if event has ended + grace.
    /// Returns number of rows updated.
    #[no_mangle]
    pub extern "C" fn edp_process_auto_rollover(
        event_id_ptr: *const c_char,
        event_end_epoch_s: i64,
        now_epoch_s: i64,
        grace_seconds: i64,
    ) -> i64 {
        if event_id_ptr.is_null() { return -1; }
        let event_id = unsafe { CStr::from_ptr(event_id_ptr) };
        let eid = match event_id.to_str() { Ok(s) => s, Err(_) => return -1 };
        match crate::db::process_auto_rollover(eid, event_end_epoch_s, now_epoch_s, grace_seconds) {
            Ok(n) => n as i64,
            Err(e) => { set_last_error(format!("auto_rollover_failed: {}", e)); -1 }
        }
    }

    /// List attendance for event as JSON array of rows.
    #[no_mangle]
    pub extern "C" fn edp_list_attendance(event_id_ptr: *const c_char) -> *mut c_char {
        if event_id_ptr.is_null() { return std::ptr::null_mut(); }
        let event_id = unsafe { CStr::from_ptr(event_id_ptr) };
        let eid = match event_id.to_str() { Ok(s) => s, Err(_) => return std::ptr::null_mut() };
        match crate::db::list_attendance(eid) {
            Ok(rows) => match serde_json::to_string(&rows) { Ok(js) => CString::new(js).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()), Err(_) => std::ptr::null_mut() },
            Err(_) => std::ptr::null_mut(),
        }
    }

    /// Remove attendance by id; returns 1 on success.
    #[no_mangle]
    pub extern "C" fn edp_remove_attendance(att_id_ptr: *const c_char, reason_ptr: *const c_char, changed_by_ptr: *const c_char) -> c_int {
        if att_id_ptr.is_null() { return 0; }
        let att = unsafe { CStr::from_ptr(att_id_ptr) };
        let reason = if reason_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(reason_ptr) }.to_str().unwrap_or("")) };
        let changed_by = if changed_by_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(changed_by_ptr) }.to_str().unwrap_or("")) };
        match crate::db::remove_attendance(att.to_str().unwrap_or(""), reason, changed_by) { Ok(true) => 1, _ => 0 }
    }

    /// Search members by query string; returns JSON array.
    #[no_mangle]
    pub extern "C" fn edp_search_members(query_ptr: *const c_char, limit: c_int) -> *mut c_char {
        if query_ptr.is_null() { return std::ptr::null_mut(); }
        let q = unsafe { CStr::from_ptr(query_ptr) };
        let lim = if limit <= 0 { 20 } else { limit } as i64;
        match crate::db::search_members(q.to_str().unwrap_or(""), lim) {
            Ok(rows) => match serde_json::to_string(&rows) { Ok(js) => CString::new(js).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()), Err(_) => std::ptr::null_mut() },
            Err(_) => std::ptr::null_mut(),
        }
    }

    /// Create walk-in; returns JSON {attendanceId, memberId, eventId, status}
    #[no_mangle]
    pub extern "C" fn edp_create_walkin(event_id_ptr: *const c_char, name_ptr: *const c_char, email_ptr: *const c_char, phone_ptr: *const c_char, company_ptr: *const c_char, immediate_checkin: bool, changed_by_ptr: *const c_char) -> *mut c_char {
        if event_id_ptr.is_null() || name_ptr.is_null() { return std::ptr::null_mut(); }
        let eid = unsafe { CStr::from_ptr(event_id_ptr) };
        let name = unsafe { CStr::from_ptr(name_ptr) };
        let email = if email_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(email_ptr) }.to_str().unwrap_or("")) };
        let phone = if phone_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(phone_ptr) }.to_str().unwrap_or("")) };
        let company = if company_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(company_ptr) }.to_str().unwrap_or("")) };
        let changed_by = if changed_by_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(changed_by_ptr) }.to_str().unwrap_or("")) };
        match crate::db::create_walkin(eid.to_str().unwrap_or(""), name.to_str().unwrap_or(""), email, phone, company, immediate_checkin, changed_by) {
            Ok(res) => match serde_json::to_string(&res) { Ok(js) => CString::new(js).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()), Err(_) => std::ptr::null_mut() },
            Err(_) => std::ptr::null_mut(),
        }
    }

    /// Merge two members (duplicate into primary). Returns number of attendance rows moved.
    #[no_mangle]
    pub extern "C" fn edp_merge_members(primary_ptr: *const c_char, dup_ptr: *const c_char) -> i64 {
        if primary_ptr.is_null() || dup_ptr.is_null() { return -1; }
        let p = unsafe { CStr::from_ptr(primary_ptr) };
        let d = unsafe { CStr::from_ptr(dup_ptr) };
        match crate::db::merge_members(p.to_str().unwrap_or(""), d.to_str().unwrap_or("")) {
            Ok(n) => n as i64,
            Err(e) => { set_last_error(format!("merge_failed: {}", e)); -1 }
        }
    }

    /// Create event; returns event id string (heap; free with edp_free_cstr)
    #[no_mangle]
    pub extern "C" fn edp_create_event(id_ptr: *const c_char, name_ptr: *const c_char, starts_ptr: *const c_char, ends_ptr: *const c_char, location_ptr: *const c_char, capacity: i64, status_ptr: *const c_char, timezone_ptr: *const c_char, description_ptr: *const c_char) -> *mut c_char {
        if name_ptr.is_null() || starts_ptr.is_null() || ends_ptr.is_null() { return std::ptr::null_mut(); }
        let id = if id_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(id_ptr) }.to_str().unwrap_or("")) };
        let name = unsafe { CStr::from_ptr(name_ptr) }.to_str().unwrap_or("");
        let starts = unsafe { CStr::from_ptr(starts_ptr) }.to_str().unwrap_or("");
        let ends = unsafe { CStr::from_ptr(ends_ptr) }.to_str().unwrap_or("");
        let loc = if location_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(location_ptr) }.to_str().unwrap_or("")) };
        let stat = if status_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(status_ptr) }.to_str().unwrap_or("")) };
        let tz = if timezone_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(timezone_ptr) }.to_str().unwrap_or("")) };
        let desc = if description_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(description_ptr) }.to_str().unwrap_or("")) };
        match crate::db::create_event(id, name, starts, ends, loc, if capacity<=0 { None } else { Some(capacity) }, stat, tz, desc) {
            Ok(eid) => CString::new(eid).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()),
            Err(e) => { set_last_error(format!("create_event_failed: {}", e)); std::ptr::null_mut() }
        }
    }

    /// Update event; returns 1 on success
    #[no_mangle]
    pub extern "C" fn edp_update_event(id_ptr: *const c_char, name_ptr: *const c_char, starts_ptr: *const c_char, ends_ptr: *const c_char, location_ptr: *const c_char, capacity: i64, status_ptr: *const c_char, timezone_ptr: *const c_char, description_ptr: *const c_char) -> c_int {
        if id_ptr.is_null() { return 0; }
        let id = unsafe { CStr::from_ptr(id_ptr) }.to_str().unwrap_or("");
        let name = if name_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(name_ptr) }.to_str().unwrap_or("")) };
        let starts = if starts_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(starts_ptr) }.to_str().unwrap_or("")) };
        let ends = if ends_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(ends_ptr) }.to_str().unwrap_or("")) };
        let loc = if location_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(location_ptr) }.to_str().unwrap_or("")) };
        let cap = if capacity<=0 { None } else { Some(capacity) };
        let stat = if status_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(status_ptr) }.to_str().unwrap_or("")) };
        let tz = if timezone_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(timezone_ptr) }.to_str().unwrap_or("")) };
        let desc = if description_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(description_ptr) }.to_str().unwrap_or("")) };
        match crate::db::update_event(id, name, starts, ends, loc, cap, stat, tz, desc) { Ok(true) => 1, _ => 0 }
    }

    /// List events; returns JSON array
    #[no_mangle]
    pub extern "C" fn edp_list_events(limit: i64, offset: i64) -> *mut c_char {
        match crate::db::list_events(if limit<=0 { 50 } else { limit }, if offset<0 { 0 } else { offset }) {
            Ok(rows) => match serde_json::to_string(&rows) { Ok(js) => CString::new(js).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()), Err(_) => std::ptr::null_mut() },
            Err(_) => std::ptr::null_mut(),
        }
    }

    #[no_mangle]
    pub extern "C" fn edp_delete_event(event_id_ptr: *const c_char) -> i64 {
        if event_id_ptr.is_null() { return -1; }
        let eid = unsafe { CStr::from_ptr(event_id_ptr) };
        match crate::db::delete_event(eid.to_str().unwrap_or("")) { Ok(n) => n as i64, Err(e) => { set_last_error(format!("delete_event_failed: {}", e)); -1 } }
    }

    /// Return count of rows where status_v2 is NULL for an event (0 if column missing)
    #[no_mangle]
    pub extern "C" fn edp_status_v2_nulls(event_id_ptr: *const c_char) -> i64 {
        if event_id_ptr.is_null() { return -1; }
        let eid = unsafe { CStr::from_ptr(event_id_ptr) };
        match crate::db::status_v2_nulls(eid.to_str().unwrap_or("")) { Ok(n) => n as i64, Err(_) => -1 }
    }

    /// Run backfill for status_v2 for a given event. Returns number of rows updated, or -1 on error.
    #[no_mangle]
    pub extern "C" fn edp_status_v2_backfill(event_id_ptr: *const c_char) -> i64 {
        if event_id_ptr.is_null() { return -1; }
        let eid = unsafe { CStr::from_ptr(event_id_ptr) };
        match crate::db::backfill_status_v2(eid.to_str().unwrap_or("")) { Ok(n) => n as i64, Err(_) => -1 }
    }

    /// Update member (global). Any NULL parameter leaves field unchanged. Returns 1 on success.
    #[no_mangle]
    pub extern "C" fn edp_update_member(
        id_ptr: *const c_char,
        email_ptr: *const c_char,
        first_ptr: *const c_char,
        last_ptr: *const c_char,
        phone_ptr: *const c_char,
        company_ptr: *const c_char,
        tags_ptr: *const c_char,
        notes_ptr: *const c_char,
    ) -> c_int {
        if id_ptr.is_null() { return 0; }
        let id = unsafe { CStr::from_ptr(id_ptr) }.to_str().unwrap_or("");
        let email = if email_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(email_ptr) }.to_str().unwrap_or("")) };
        let first = if first_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(first_ptr) }.to_str().unwrap_or("")) };
        let last = if last_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(last_ptr) }.to_str().unwrap_or("")) };
        let phone = if phone_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(phone_ptr) }.to_str().unwrap_or("")) };
        let company = if company_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(company_ptr) }.to_str().unwrap_or("")) };
        let tags = if tags_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(tags_ptr) }.to_str().unwrap_or("")) };
        let notes = if notes_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(notes_ptr) }.to_str().unwrap_or("")) };
        match crate::db::update_member(id, email, first, last, phone, company, tags, notes) {
            Ok(true) => 1,
            Ok(false) => 0,
            Err(e) => { set_last_error(format!("update_member_failed: {}", e)); 0 }
        }
    }

    /// Create member; returns member id string
    #[no_mangle]
    pub extern "C" fn edp_create_member(
        email_ptr: *const c_char,
        first_ptr: *const c_char,
        last_ptr: *const c_char,
        phone_ptr: *const c_char,
        company_ptr: *const c_char,
        tags_ptr: *const c_char,
        notes_ptr: *const c_char,
    ) -> *mut c_char {
        let email = if email_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(email_ptr) }.to_str().unwrap_or("")) };
        let first = if first_ptr.is_null() { "" } else { unsafe { CStr::from_ptr(first_ptr) }.to_str().unwrap_or("") };
        let last = if last_ptr.is_null() { "" } else { unsafe { CStr::from_ptr(last_ptr) }.to_str().unwrap_or("") };
        let phone = if phone_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(phone_ptr) }.to_str().unwrap_or("")) };
        let company = if company_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(company_ptr) }.to_str().unwrap_or("")) };
        let tags = if tags_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(tags_ptr) }.to_str().unwrap_or("")) };
        let notes = if notes_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(notes_ptr) }.to_str().unwrap_or("")) };
        match crate::db::create_member(email, first, last, phone, company, tags, notes) {
            Ok(id) => CString::new(id).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()),
            Err(e) => { set_last_error(format!("create_member_failed: {}", e)); std::ptr::null_mut() }
        }
    }

    #[no_mangle]
    pub extern "C" fn edp_member_profile(member_id_ptr: *const c_char) -> *mut c_char {
        if member_id_ptr.is_null() { return std::ptr::null_mut(); }
        let mid = unsafe { CStr::from_ptr(member_id_ptr) };
        match crate::db::member_profile(mid.to_str().unwrap_or("")) { Ok(p) => match serde_json::to_string(&p) { Ok(js) => CString::new(js).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()), Err(_) => std::ptr::null_mut() }, Err(_) => std::ptr::null_mut() }
    }

    #[no_mangle]
    pub extern "C" fn edp_export_json_for_event(event_id_ptr: *const c_char) -> *mut c_char {
        if event_id_ptr.is_null() { return std::ptr::null_mut(); }
        let eid = unsafe { CStr::from_ptr(event_id_ptr) };
        match crate::db::export_json_for_event(eid.to_str().unwrap_or("")) { Ok(val) => match serde_json::to_string(&val) { Ok(js) => CString::new(js).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()), Err(_) => std::ptr::null_mut() }, Err(_) => std::ptr::null_mut() }
    }

    #[no_mangle]
    pub extern "C" fn edp_list_status_audit(event_id_ptr: *const c_char, attendance_id_ptr: *const c_char, limit: i64) -> *mut c_char {
        let eid = if event_id_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(event_id_ptr) }.to_str().unwrap_or("")) };
        let aid = if attendance_id_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(attendance_id_ptr) }.to_str().unwrap_or("")) };
        match crate::db::list_status_audit(eid, aid, if limit<=0 { 50 } else { limit }) { Ok(rows) => match serde_json::to_string(&rows) { Ok(js) => CString::new(js).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()), Err(_) => std::ptr::null_mut() }, Err(_) => std::ptr::null_mut() }
    }

    #[no_mangle]
    pub extern "C" fn edp_bulk_status_update(event_id_ptr: *const c_char, attendee_ids_ptr: *const c_char, new_status_ptr: *const c_char, event_in_progress: bool, has_manager_override: bool, reason_ptr: *const c_char, changed_by_ptr: *const c_char) -> i64 {
        if event_id_ptr.is_null() || attendee_ids_ptr.is_null() || new_status_ptr.is_null() { return -1; }
        let eid = unsafe { CStr::from_ptr(event_id_ptr) };
        let ids_c = unsafe { CStr::from_ptr(attendee_ids_ptr) };
        let ids_s = ids_c.to_str().unwrap_or("");
        let ids: Vec<&str> = ids_s.split(',').filter(|s| !s.is_empty()).collect();
        let ns = unsafe { CStr::from_ptr(new_status_ptr) };
        let reason = if reason_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(reason_ptr) }.to_str().unwrap_or("")) };
        let changed_by = if changed_by_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(changed_by_ptr) }.to_str().unwrap_or("")) };
        match crate::db::bulk_status_update(eid.to_str().unwrap_or(""), &ids, ns.to_str().unwrap_or(""), event_in_progress, has_manager_override, reason, changed_by) { Ok(n) => n as i64, Err(e) => { set_last_error(format!("bulk_update_failed: {}", e)); -1 } }
    }

    /// Update attendance status with validation and audit. Returns 1 on success, 0 on failure and sets last error.
    #[no_mangle]
    pub extern "C" fn edp_update_status(
        attendance_id_ptr: *const c_char,
        new_status_ptr: *const c_char,
        event_in_progress: bool,
        has_manager_override: bool,
        reason_ptr: *const c_char,
        changed_by_ptr: *const c_char,
    ) -> c_int {
        if attendance_id_ptr.is_null() || new_status_ptr.is_null() { return 0; }
        let att = unsafe { CStr::from_ptr(attendance_id_ptr) };
        let new = unsafe { CStr::from_ptr(new_status_ptr) };
        let reason = if reason_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(reason_ptr) }.to_str().unwrap_or("")) };
        let changed_by = if changed_by_ptr.is_null() { None } else { Some(unsafe { CStr::from_ptr(changed_by_ptr) }.to_str().unwrap_or("")) };
        match crate::db::update_status(att.to_str().unwrap_or("") , new.to_str().unwrap_or("") , event_in_progress, has_manager_override, reason, changed_by) {
            Ok(true) => 1,
            Ok(false) => { set_last_error("update_failed".into()); 0 },
            Err(e) => { set_last_error(e); 0 }
        }
    }

    /// Get and clear the last error string (if any). Caller must free.
    #[no_mangle]
    pub extern "C" fn edp_last_error_message() -> *mut c_char {
        match take_last_error() {
            Some(s) => CString::new(s).ok().map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut()),
            None => std::ptr::null_mut(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::status::AttendeeStatus::*;
    use super::validate::{validate_status_transition, TransitionCheck::*};
    use super::util::{normalize_status_str, auto_rollover_due};

    #[test]
    fn dna_requires_override_during_event() {
        assert_eq!(validate_status_transition(Preregistered, Dna, true, false), NeedsManagerOverride);
        assert_eq!(validate_status_transition(Preregistered, Dna, true, true), Ok);
    }

    #[test]
    fn undo_checked_in_requires_reason() {
        assert_eq!(validate_status_transition(Checkedin, Preregistered, false, false), NeedsReason);
        assert_eq!(validate_status_transition(Checkedin, Walkin, false, false), NeedsReason);
        assert_eq!(validate_status_transition(Checkedin, Dna, false, true), NeedsReason);
    }

    #[test]
    fn simple_to_checked_in_is_ok() {
        assert_eq!(validate_status_transition(Preregistered, Checkedin, false, false), Ok);
        assert_eq!(validate_status_transition(Walkin, Checkedin, false, false), Ok);
    }
}
