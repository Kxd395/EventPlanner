use eventdesk_core::db::{set_db_path, commit_csv_for_event, export_csv_for_event};

#[test]
fn export_includes_header_and_rows() {
    let tmp = tempfile::NamedTempFile::new().expect("tmp");
    let path = tmp.path().to_string_lossy().to_string();
    assert!(set_db_path(&path));
    let csv = "name,email,company,status\nJane,jane@x.io,Orbit,checkedin\nSam,sam@y.co,ACME,registered\n";
    let outcome = commit_csv_for_event("evt_exp", csv).expect("commit");
    assert_eq!(outcome.rowsImported, 2);
    let out = export_csv_for_event("evt_exp").expect("export");
    let mut lines = out.lines();
    let header = lines.next().unwrap_or("");
    assert!(header.contains("memberId,attendeeId,eventId,name,email,company,status"));
    let rows: Vec<_> = lines.collect();
    assert_eq!(rows.len(), 2);
}

