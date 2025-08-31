# SSOT Consolidation Change Log
Last Updated: 2025-08-29 23:15:47Z

Version: 1.1.0 (consolidated)

## Summary
- Canonical status codes unified to `preregistered|walkin|checkedin|dna`.
- UI labels standardized: Pre‑Registered, Walk‑in, Checked‑In, Did Not Attend (DNA).
- Colors standardized: Blue, Purple, Green, Gray.
- Status stored in `event_attendance.status` (per‑event), not on people.
- Migration target corrected to `event_attendance.status_v2` (not attendees).

## Reconciled Conflicts
- PRD enum (`registered|walkIn|checkedIn|noShow`) → replaced with canonical codes.
- PRD colors (Orange Walk‑in, Red No‑show) → replaced with Purple/Gray.
- Migration doc targeting person/attendee table → retargeted to `event_attendance`.
- Analytics status values → aligned to canonical codes.

## Actions Required
- Update UI string resources and badges.
- Update API/DTO validation to canonical codes.
- Run DB migration (dual‑write → backfill → pivot → cleanup).
- Update analytics schema assertions.

## Acceptance
- Single source of truth is `docs/ssot/SSOT.md`.
- All downstream docs reference this version.
