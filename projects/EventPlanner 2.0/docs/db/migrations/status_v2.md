# Migration — Unified Attendee Status (status_v2 on event_attendance)
Last Updated: 2025-08-29 23:15:47Z

Authoritative model: `../ssot/SSOT.md`

## Target
- Table: `event_attendance`
- Column: `status_v2 TEXT CHECK(status_v2 IN ('preregistered','walkin','checkedin','dna'))` (nullable in Phase 0–2, NOT NULL after pivot)

## Phases
1) Phase 0 — Prep
```sql
ALTER TABLE event_attendance
ADD COLUMN status_v2 TEXT CHECK (status_v2 IN ('preregistered','walkin','checkedin','dna'));
```

2) Phase 1 — Dual‑write (app layer)
- On any status change, write both legacy `status` and `status_v2`.
- Emit analytics `attendee_status_change` with canonical codes.

Pseudo:
```ts
function setStatus(attendanceId, newStatus) {
  assertInSet(newStatus, ['preregistered','walkin','checkedin','dna']);
  db.run('UPDATE event_attendance SET status_v2=?, updated_at=CURRENT_TIMESTAMP WHERE id=?', [newStatus, attendanceId]);
  // Legacy path — remove after Phase 4
  db.run('UPDATE event_attendance SET status=? WHERE id=?', [legacyFrom(newStatus), attendanceId]);
}
```

3) Phase 2 — Backfill historic rows
```sql
UPDATE event_attendance
SET status_v2 = (
  CASE
    WHEN status IN ('checkedin','attended','present') THEN 'checkedin'
    WHEN status IN ('dna','noshow','no_show') THEN 'dna'
    WHEN status IN ('walkin','walk_in') THEN 'walkin'
    ELSE 'preregistered'
  END
)
WHERE status_v2 IS NULL;
```

4) Phase 3 — Read pivot
- Feature flag: prefer `status_v2` for reads.
- Integrity check: 0 NULL `status_v2`.

5) Phase 4 — Stop legacy writes
- Only write `status_v2`.
- CI guard fails if legacy write path invoked.

6) Phase 5 — Cleanup
- Optionally drop legacy `status` column after backup, or keep as shadow until next cycle.

## Verification Queries
```sql
SELECT status_v2, COUNT(*) FROM event_attendance GROUP BY status_v2;
SELECT COUNT(*) AS null_rows FROM event_attendance WHERE status_v2 IS NULL; -- expect 0 after backfill
```

## Rollback
- Keep feature flags to revert read pivot.
- Re-enable legacy writes temporarily if needed.

## Acceptance
- Canonical codes appear in all APIs/DTOs/analytics.
- 0 NULL `status_v2` rows post-backfill.
- Legacy writes disabled and guarded in CI.
