use eventdesk_core::db::{set_db_path, commit_csv_for_event, counts_by_status};

#[test]
fn counts_by_status_reports_expected() {
    let tmp = tempfile::NamedTempFile::new().expect("tmp");
    let path = tmp.path().to_string_lossy().to_string();
    assert!(set_db_path(&path));
    let csv = "name,email,company,status\nA,a@x.io,Co,registered\nB,b@x.io,Co,walkin\nC,c@x.io,Co,checkedin\nD,d@x.io,Co,\n";
    let _ = commit_csv_for_event("evt_counts", csv).expect("commit");
    let c = counts_by_status("evt_counts").expect("counts");
    assert_eq!(c.preregistered, 2); // A and D default preregistered
    assert_eq!(c.walkin, 1);
    assert_eq!(c.checkedin, 1);
    assert_eq!(c.dna, 0);
}

