use eventdesk_core::db::{set_db_path, commit_csv_for_event};
use rusqlite::Connection;
use eventdesk_core::db;

#[test]
fn csv_commit_writes_audit_log() {
    let _ = set_db_path(":memory:");
    // Perform a commit
    let csv = "name,email,company,status\nJane,jane@x.io,Orbit,checkedin";
    let out = commit_csv_for_event("evt_a", csv).expect("commit");
    assert_eq!(out.rowsImported, 1);

    // Verify audit entries exist
    // Open the same DB (in-memory set in module opens in-memory; to verify, we re-apply schema and query via new conn)
    let conn = Connection::open_in_memory().expect("open mem");
    // Because set_db_path used in-memory, commit applied on a different handle; we cannot verify across handles.
    // Instead, set a file-backed temporary DB and re-run.
}

#[test]
fn csv_commit_writes_audit_log_filebacked() {
    let tmp = tempfile::NamedTempFile::new().expect("tmp");
    let path = tmp.path().to_string_lossy().to_string();
    let _ = set_db_path(&path);
    let csv = "name,email,company,status\nJane,jane@x.io,Orbit,checkedin";
    let out = commit_csv_for_event("evt_a", csv).expect("commit");
    assert_eq!(out.rowsImported, 1);
    let conn = Connection::open(&path).expect("open");
    let cnt: i64 = conn.query_row("SELECT COUNT(*) FROM status_audit_log", [], |r| r.get(0)).expect("count");
    assert_eq!(cnt, 1);

    // Now test updateStatus validation + audit
    // Fetch attendance id
    let att_id: String = conn.query_row("SELECT id FROM event_attendance LIMIT 1", [], |r| r.get(0)).unwrap();
    // Update to preregistered (undo) without reason should fail
    let res = db::update_status(&att_id, "preregistered", true, false, None, Some("test"));
    assert!(res.is_err());
    // With reason should succeed
    let res2 = db::update_status(&att_id, "preregistered", true, false, Some("correction"), Some("test"));
    assert!(res2.is_ok());
    let cnt2: i64 = conn.query_row("SELECT COUNT(*) FROM status_audit_log", [], |r| r.get(0)).unwrap();
    assert_eq!(cnt2, 2);
}
