use eventdesk_core::analytics::validate_event_json;

#[test]
fn analytics_valid_event_passes() {
    let json = r#"{
        "name":"attendee_status_change",
        "timestamp":"2025-08-29T12:00:00Z",
        "actorId":"u1",
        "context": {"eventId":"e1","attendanceId":"a1"},
        "payload": {"priorStatus":"preregistered","newStatus":"checkedin"}
    }"#;
    assert!(validate_event_json(json));
}

#[test]
fn analytics_pii_in_payload_is_rejected() {
    let json = r#"{
        "name":"attendee_status_change",
        "timestamp":"2025-08-29T12:00:00Z",
        "payload": {"emails":["x@y.co"]}
    }"#;
    assert!(!validate_event_json(json));
}

#[test]
fn analytics_missing_timestamp_is_rejected() {
    let json = r#"{
        "name":"attendee_status_change",
        "payload": {}
    }"#;
    assert!(!validate_event_json(json));
}

