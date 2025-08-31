# EventDeskPro — Product Requirements (Aligned to SSOT v1.1.0)
Last Updated: 2025-08-29 23:15:47Z

## 1. Goals
- Enable full attendee management at the event level (inline contact edit + participation edit).
- Link Event Attendees to global Members with deep-link navigation both ways.
- Unify status vocabulary and storage per SSOT codes.

## 2. Key Concepts
- Member: Global person record (deduped by email).
- Attendee (Participation): A Member’s record within an Event. Holds status and event-specific data.
- Relationship: One Member ⇄ Many Attendees (max one per event).

## 3. Status Model (Authoritative)
- Codes: `preregistered | walkin | checkedin | dna`
- Labels: Pre-Registered, Walk-in, Checked-In, Did Not Attend (DNA)
- Storage: `event_attendance.status` (per-event)
- See: `SSOT.md`

## 4. Requirements by Page

### 4.1 Event Detail → Attendees
- List fields: Name, Email, Company, Status badge, Actions.
- Side panel (row → View):
  - Contact (global): Name, Email, Phone, Company, Tags, Notes (saves to Member).
  - Participation (event): Status, Ticket/Seat, Check-in time, Source, Event notes (saves to Attendee).
- Actions: Open Member Profile; Remove from Event.
- Filters: search (name/email), status, tags/company.
- Import CSV: create-or-link with preview (dedupe by email) + partial commit.
- Export CSV: contact + event fields.
- Bulk actions: Email, Mark Checked-In, Mark DNA, Remove.

Acceptance
- Contact edits update Member globally; participation edits scoped to event.
- Status changes reflect immediately; counts update.
- Deep-link to Member profile and return to Attendees with highlight.
- Import prevents duplicate Members; links by email.
- Export contains accurate, labeled columns.

### 4.2 Members (Global Directory)
- Directory: search, sort (name, last activity), filter (tags, company).
- Profile: Contact card, Event history (event, date, status, check-in time).
- Actions: Edit Contact; Open in Event (lands on Attendees tab, highlighted row).
- Deduplication: email primary key; email change prompts merge or create.

Acceptance
- “Open in Event” returns to correct event and highlights the attendee.
- Merges preserve event history.

### 4.3 Dashboard / Events List (Condensed)
- Dashboard: status summary, upcoming events with Manage (deep-link), recent attendees → Member profile.
- Events List: clickable rows → Event Detail; action icons (Edit, View Attendees), bulk actions with confirmation.

## 5. Navigation Contracts
See `NAVIGATION.md` for routes, highlight param, and acceptance.

## 6. Walk‑in Flow (Minimum)
- Quick search existing Member by email/name → link if found.
- If not found: minimal create (name required; email optional); initial status = `walkin`.
- Optional immediate check‑in toggle.

Acceptance
- ≤ 3 required inputs; duplicate detection by email; offline queue allowed.

## 7. Accessibility & Keyboard
- Shortcuts: `/` (search), `N` (new event), `A` (add attendee), `W` (walk‑in), `Esc` (close), `?` (overlay).
- Focus management: open panel focuses first field; close returns focus to row.
- ARIA/labels on interactive status buttons.

## 8. Analytics (Baseline)
- Events: attendee_panel_open, attendee_contact_save, attendee_participation_save, attendee_status_change, walk_in_create, csv_import_preview, csv_import_commit, csv_export, member_profile_open, open_in_event
- Status values use canonical codes.
- See `docs/ANALYTICS.md`.

## 9. Import/Export Spec (Summary)
- Export default: memberId, attendanceId, eventId, name, email, company, status, ticketType, seat, checkedInAt, source, tags, eventNotes, createdAt
- Import accepted: name/firstName/lastName, email, company, status, ticketType, seat, tags, notes
- Preview metrics: total, valid, duplicates, errors; partial commit of valid rows.

## 10. Testing & CI
- Coverage ≥ 70% (Phase 1 exit), migration guard for legacy status writes.
- See `docs/TESTING.md`.

## 11. Phase Execution Order
1) Attendee Editing & Linking
2) Navigation & A11y polish
3) Reports & Settings
