use eventdesk_core::analytics_store;
use std::fs;

#[test]
fn analytics_store_appends_lines() {
    let tmp = tempfile::NamedTempFile::new().expect("tmp");
    let path = tmp.path().to_string_lossy().to_string();
    assert!(analytics_store::set_path(&path));
    analytics_store::append("{\"name\":\"csv_export\",\"timestamp\":\"2025-08-29T12:00:00Z\"}").expect("append1");
    analytics_store::append("{\"name\":\"member_profile_open\",\"timestamp\":\"2025-08-29T12:01:00Z\"}").expect("append2");
    let data = fs::read_to_string(&path).expect("read");
    let lines: Vec<_> = data.lines().collect();
    assert_eq!(lines.len(), 2);
}

