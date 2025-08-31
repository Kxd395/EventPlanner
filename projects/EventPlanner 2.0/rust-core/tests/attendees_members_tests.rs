use eventdesk_core::db::{set_db_path, commit_csv_for_event, list_attendance, remove_attendance, search_members, create_walkin};

#[test]
fn list_and_remove_attendance_flow() {
    let tmp = tempfile::NamedTempFile::new().expect("tmp");
    let path = tmp.path().to_string_lossy().to_string();
    assert!(set_db_path(&path));
    let csv = "name,email,company,status\nA,a@x.io,Co,registered\nB,b@x.io,Co,walkin\n";
    let _ = commit_csv_for_event("evt_list", csv).expect("commit");
    let rows = list_attendance("evt_list").expect("list");
    assert_eq!(rows.len(), 2);
    let att_id = rows[0].attendeeId.clone();
    let ok = remove_attendance(&att_id, Some("cleanup"), Some("test")).expect("remove");
    assert!(ok);
    let rows2 = list_attendance("evt_list").expect("list2");
    assert_eq!(rows2.len(), 1);
}

#[test]
fn search_and_walkin_flow() {
    let tmp = tempfile::NamedTempFile::new().expect("tmp");
    let path = tmp.path().to_string_lossy().to_string();
    assert!(set_db_path(&path));
    // Seed via CSV
    let csv = "name,email,company,status\nJane Doe,jane@x.io,Orbit,registered\n";
    let _ = commit_csv_for_event("evt_walk", csv).expect("commit");
    // Search members
    let members = search_members("jane", 10).expect("search");
    assert!(members.iter().any(|m| m.email.as_deref() == Some("jane@x.io")));
    // Create a walk-in with immediate check-in
    let res = create_walkin("evt_walk", "Walk In", None, None, Some("Orbit"), true, Some("test")).expect("walkin");
    assert_eq!(res.status, "checkedin");
}

