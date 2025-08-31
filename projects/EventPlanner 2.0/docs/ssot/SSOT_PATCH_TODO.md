# External Docs Patch Plan (to sync with SSOT v1.1.0)
Last Updated: 2025-08-29 23:15:47Z

Applies to: `/Applications/MyApps/AxxessPhilly/projects/EventDeskPro/docs`

Note: Paths below reference original files; update them to match `docs/ssot/SSOT.md` in this repo.

## 1) PRD_Update.md
- Section 12 (Unified Status Model Spec):
  - Replace enum `registered|walkIn|checkedIn|noShow` → `preregistered|walkin|checkedin|dna`.
  - Update Display Mapping colors to Blue / Purple / Green / Gray.
- Sections 4.1/4.2/11:
  - Ensure UI strings use “Pre‑Registered”, “Walk‑in”, “Checked‑In”, “Did Not Attend (DNA)”.

## 2) analytics-events.md
- Field definitions for `priorStatus/newStatus` → canonical codes `preregistered|walkin|checkedin|dna`.

## 3) status-model-migration.md
- Target table is `event_attendance`, not `attendees`/person table.
- Add `status_v2` to `event_attendance`.
- Keep phases (dual‑write, backfill, pivot, cleanup) and mapping priority.

## 4) SSOT_LOCATION_GUIDE.md
- Status Management System summary → 4‑state vocabulary using Pre‑Registered/Walk‑in/Checked‑In/DNA and Purple/Gray colors.
- Point to `SSOT.md` (this repo) as canonical summary.

## 5) ascii-ui-design.md (if needed)
- Validate vocabulary and color chips align with SSOT.

## 6) system-logic-ssot.md
- Already aligned; ensure cross‑references to PRD/Analytics/Migration reflect codes above.

## Acceptance
- All references to legacy terms (Registered/No‑Show) removed in favor of SSOT vocabulary.
- All enumerations and code examples use canonical codes.
