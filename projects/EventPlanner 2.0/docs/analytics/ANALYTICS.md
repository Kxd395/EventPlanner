# Analytics Events (Aligned to SSOT)
Last Updated: 2025-08-29 23:15:47Z

## Schema
```json
{
  "name": "string:kebab-case",
  "timestamp": "ISO8601",
  "actorId": "string|nullable",
  "context": { "eventId?": "string", "memberId?": "string", "attendanceId?": "string" },
  "payload": { },
  "pii": { "emails?": ["..."], "names?": ["..."] }
}
```
- PII only inside `pii` object.
- Status values use canonical codes: `preregistered|walkin|checkedin|dna`.

## Core Events
- attendee_panel_open (attendanceId, eventId)
- attendee_contact_save (memberId, changedFields[]; pii.emails?, pii.names?)
- attendee_participation_save (attendanceId, changedFields[], priorStatus, newStatus)
- attendee_status_change (attendanceId, priorStatus, newStatus, origin=single|bulk)
- walk_in_create (attendanceId, eventId, hasEmail; pii.emails?, pii.names?)
- csv_import_preview (eventId?, rowsTotal, duplicates, errors)
- csv_import_commit (eventId?, rowsImported, rowsErrored)
- csv_export (eventId?, scope=all|filtered|selected, rowCount)
- member_profile_open (memberId)
- open_in_event (memberId, eventId, highlightAttendanceId)

## Validation
- Reject missing `name` or `timestamp`.
- Enforce whitelist of core event names (Phase 1).
- Validate `priorStatus/newStatus` ∈ {preregistered,walkin,checkedin,dna}.
