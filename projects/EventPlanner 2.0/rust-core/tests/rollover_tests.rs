use eventdesk_core::db::{set_db_path, commit_csv_for_event, process_auto_rollover, counts_by_status};

#[test]
fn auto_rollover_marks_dna_after_grace() {
    let tmp = tempfile::NamedTempFile::new().expect("tmp");
    let path = tmp.path().to_string_lossy().to_string();
    assert!(set_db_path(&path));
    let csv = "name,email,company,status\nA,a@x.io,Co,registered\nB,b@x.io,Co,walkin\nC,c@x.io,Co,checkedin\n";
    let _ = commit_csv_for_event("evt_roll", csv).expect("commit");
    // event ended at t=100, now=100+grace
    let updated = process_auto_rollover("evt_roll", 100, 100 + 3*3600, 3*3600).expect("rollover");
    assert_eq!(updated, 2);
    let c = counts_by_status("evt_roll").expect("counts");
    assert_eq!(c.dna, 2);
    assert_eq!(c.checkedin, 1);
}

