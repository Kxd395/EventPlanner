use eventdesk_core::{
    status::AttendeeStatus as S,
    validate::{validate_status_transition as v, TransitionCheck as C},
    util::{normalize_status_str, auto_rollover_due},
    csvops::preview_csv_text,
};

#[test]
fn normalize_variants() {
    assert_eq!(normalize_status_str("Registered"), Some(S::Preregistered));
    assert_eq!(normalize_status_str("walk-in"), Some(S::Walkin));
    assert_eq!(normalize_status_str("checked in"), Some(S::Checkedin));
    assert_eq!(normalize_status_str("no_show"), Some(S::Dna));
    assert_eq!(normalize_status_str("unknown"), None);
}

#[test]
fn transition_rules() {
    assert_eq!(v(S::Preregistered, S::Checkedin, false, false), C::Ok);
    assert_eq!(v(S::Checkedin, S::Walkin, false, false), C::NeedsReason);
    assert_eq!(v(S::Walkin, S::Dna, true, false), C::NeedsManagerOverride);
    assert_eq!(v(S::Walkin, S::Dna, true, true), C::Ok);
}

#[test]
fn rollover_check() {
    let end = 1_000_000;
    let grace = 3600; // 1h
    assert!(!auto_rollover_due(end, grace, end + grace - 1));
    assert!(auto_rollover_due(end, grace, end + grace));
}

#[test]
fn csv_preview_basic() {
    let csv = "name,email\nJane,jane@x.io\nSam,sam@y.co\nDup,jane@x.io\nNoEmail,\n";
    let preview = preview_csv_text(csv).expect("preview");
    assert_eq!(preview.totals.total, 4);
    assert_eq!(preview.totals.valid, 4 - 1); // One error: missing email and name
    assert_eq!(preview.totals.duplicates, 1);
    assert_eq!(preview.errors.len(), 1);
}

