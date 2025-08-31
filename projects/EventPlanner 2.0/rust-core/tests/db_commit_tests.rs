use eventdesk_core::db::{set_db_path, commit_csv_for_event};

#[test]
fn commit_csv_for_event_imports_and_detects_duplicates() {
    // Use in-memory DB for isolation
    let _ = set_db_path(":memory:");

    let csv = "name,email,company,status\nJane Doe,jane@x.io,Orbit,checkedIn\nSam,sam@y.co,ACME,registered\nDup,jane@x.io,Orbit,\nNo Email Only Name,,ACME,walkin\n,,,");

    let outcome = commit_csv_for_event("evt_1", csv).expect("commit");
    // Expect: 3 imported (Jane, Sam, No Email), 1 duplicate (second jane), 1 error (empty row)
    assert_eq!(outcome.rowsImported, 3);
    assert_eq!(outcome.duplicates, 1);
    assert_eq!(outcome.rowsErrored, 1);
}

