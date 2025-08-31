# EventDeskPro — System Logic Single Source of Truth (SSOT)
Last Updated: 2025-08-29 23:15:47Z

Version: 1.1.0
Status: AUTHORITATIVE — All platforms (Swift, Rust, Web) MUST comply
Owners: Product + Architecture (changes require joint approval)

## 1. Domain & Vocabulary

- Member: Global person record (deduped by email). One per real person.
- Attendee: Participation record for a Member at a specific Event.
- Relationship: One Member ⇄ Many Attendees (max one per Event).

## 2. Attendee Status (Canonical)

- Codes (stored): `preregistered | walkin | checkedin | dna`
- UI Labels: Pre-Registered, Walk-in, Checked-In, Did Not Attend (DNA)
- Colors: Blue `#2563eb`, Purple `#8b5cf6`, Green `#16a34a`, Gray `#6b7280`
- Derived (not stored):
  - `isCheckedIn = (status == checkedin)`
  - `isDNA = (status == dna)`

## 3. State Machine & Safeguards

- Allowed transitions: Any → preregistered | walkin | checkedin | dna
- Safeguards:
  - → checkedin: no confirmation required
  - checkedin → any: requires reason (audit)
  - → dna during event: manager override required
  - Bulk early DNA: manager confirmation required
- Auto‑rollover: At `event.end + grace(3h)`, any `preregistered|walkin` without check‑in becomes `dna` (audit entry + notification). Grace period configurable (1–6h; default 3h).

## 4. Data Model (Authoritative)

- `members` (global people) — deduped by email; membership tier/flags live here.
- `events` — core event metadata.
- `event_attendance` (attendee participation) — status lives here.
- `status_audit_log` — every status change w/ prior, new, reason, actor, timestamp.

Schema (SQLite-friendly):

```sql
CREATE TABLE members (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  company TEXT,
  tags TEXT, -- comma- or JSON-encoded
  notes TEXT,
  membership_tier TEXT DEFAULT 'attendee', -- e.g. attendee|member (org-level)
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE events (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  starts_at DATETIME NOT NULL,
  ends_at DATETIME NOT NULL,
  location TEXT,
  capacity INTEGER,
  status TEXT, -- active|draft|completed
  timezone TEXT DEFAULT 'UTC',
  description TEXT
);

CREATE TABLE event_attendance (
  id TEXT PRIMARY KEY,
  member_id TEXT NOT NULL REFERENCES members(id),
  event_id TEXT NOT NULL REFERENCES events(id),
  status TEXT NOT NULL CHECK(status IN ('preregistered','walkin','checkedin','dna')) DEFAULT 'preregistered',
  ticket_type TEXT,
  seat TEXT,
  source TEXT, -- prereg|walkin
  checked_in_at DATETIME,
  event_notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(member_id, event_id)
);

CREATE TABLE status_audit_log (
  id TEXT PRIMARY KEY,
  attendance_id TEXT NOT NULL REFERENCES event_attendance(id),
  prior_status TEXT,
  new_status TEXT NOT NULL,
  reason TEXT,
  changed_by TEXT,
  changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 5. API/FFI Contracts (Platform Agnostic)

- `listEvents(): Event[]`
- `listAttendance(eventId, filters?): Attendance[]`
- `updateStatus(attendanceId, newStatus, opts?: { reason?, managerOverride?, origin?: 'single'|'bulk' }): Attendance`
- `createWalkin(eventId, contact, opts?: { immediateCheckIn?: boolean }): Attendance`
- `findOrCreateMember(contact): Member`
- `openMemberProfile(memberId): MemberDetail`
- CSV: `previewImport(eventId, file|rows) → { totals, duplicates, errors, previewId }` then `commitImport(previewId)`
- Analytics emit: `emit(name, context, payload, pii?)` with taxonomy below

DTO status values MUST be one of: `preregistered | walkin | checkedin | dna`.

## 6. Analytics Taxonomy (Phase 1)

- Schema: `{ name, timestamp, actorId, context{eventId?,memberId?,attendanceId?}, payload{...}, pii{ emails?[], names?[] } }`
- Core events: attendee_panel_open, attendee_contact_save, attendee_participation_save, attendee_status_change, walk_in_create, csv_import_preview, csv_import_commit, csv_export, member_profile_open, open_in_event
- Status values in analytics payloads use canonical codes above.
- PII ONLY inside `pii`.

## 7. Migration Plan (Legacy → SSOT)

Target table: `event_attendance`. Do NOT store status on members.

Phases:
1) Add `status_v2 TEXT CHECK(...)` to `event_attendance` (nullable initially)
2) Dual‑write from UI to both legacy and `status_v2`
3) Backfill: map booleans/legacy strings → `status_v2`
4) Read pivot: prefer `status_v2` (feature flag)
5) Stop legacy writes; enforce NOT NULL
6) Drop legacy columns after 24h equivalent clean run

Mapping priority: checkedin → dna → walkin → preregistered (first match wins for legacy flags).

Acceptance:
- 0 NULL `status_v2` rows post‑backfill
- UI emits only canonical codes; analytics payloads validated
- Legacy writes disabled after pivot; guard in CI

## 8. Navigation Contracts (Deep‑Linkable)

- `/members` → global directory
- `/members/{memberId}` → profile (event history)
- `/events` → events list
- `/events/{eventId}` → event detail (Overview default)
- `/events/{eventId}?tab=attendees` → attendees tab
- `/events/{eventId}?tab=attendees&highlight={attendanceId}` → highlight row

Browser/app back restores tab + scroll + highlight context.

## 9. Change Control

- Any change to codes, transitions, or schema requires updating this doc first.
- Downstream: PRD, Analytics, Migration, and code gen must sync in the same change.

## 10. Implementation Checklist (Swift + Rust)

- Status enum matches canonical codes
- UI labels and colors updated per SSOT
- Transition guards + reason capture implemented
- Auto‑rollover job + settings (grace, override)
- Audit log on all status changes
- CSV preview/commit with dedupe and partial success
- Analytics emission with PII boundaries
- Migration flags + CI guard against legacy writes
