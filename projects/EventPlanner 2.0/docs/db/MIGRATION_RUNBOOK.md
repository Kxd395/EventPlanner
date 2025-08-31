# Migration Runbook — Unified Attendee Status
Last Updated: 2025-08-29 23:15:47Z

Authoritative: `../ssot/SSOT.md`, migration details: `migrations/status_v2.md`

## Phases & Commands (SQLite)

1) Prep (Phase 0)
```sql
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL; -- reduce lock contention during backfill

-- Safety: full backup recommended before structural changes
-- .backup main backup_before_status_v2.sqlite

ALTER TABLE event_attendance ADD COLUMN status_v2 TEXT CHECK (status_v2 IN ('preregistered','walkin','checkedin','dna'));
CREATE INDEX IF NOT EXISTS idx_event_attendance_status_v2 ON event_attendance(status_v2);
```

2) Enable Dual‑Write (Phase 1)
- App layer writes both legacy `status` and `status_v2` on change.
- Add monitoring for mismatches (optional query).

3) Backfill (Phase 2)
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

For large tables, prefer chunked updates to avoid long locks:
```sql
-- Repeat with adjusted rowid windows until 0 rows affected
UPDATE event_attendance
SET status_v2 = (
  CASE
    WHEN status IN ('checkedin','attended','present') THEN 'checkedin'
    WHEN status IN ('dna','noshow','no_show') THEN 'dna'
    WHEN status IN ('walkin','walk_in') THEN 'walkin'
    ELSE 'preregistered'
  END
)
WHERE status_v2 IS NULL AND rowid BETWEEN 1 AND 50000;
```

4) Read Pivot (Phase 3)
- Flip feature flag to prefer `status_v2` reads.
- Verify 0 NULL `status_v2` rows.

Recommended feature flags:
- `status_v2_dual_write=true` (Phase 1–3)
- `status_v2_read_pivot=true` (Phase 3+)

5) Stop Legacy Writes (Phase 4)
- Remove legacy `status` writes from app.
- Add CI guard to fail builds on legacy write paths.

Recommended CI guard (pseudo):
- Static check disallowing writes to `event_attendance.status` after Phase 4.
- Unit/integration test asserting only canonical codes written to `status_v2`.

6) Cleanup (Phase 5)
- Optional: Drop legacy `status` after a stable period; backup first.
```sql
ALTER TABLE event_attendance RENAME COLUMN status TO status_legacy; -- optional soft cleanup first
-- After observation window and backup
-- ALTER TABLE event_attendance DROP COLUMN status; -- if supported; otherwise recreate table without column
```

## Verification
```sql
SELECT status_v2, COUNT(*) FROM event_attendance GROUP BY status_v2;
SELECT COUNT(*) AS null_rows FROM event_attendance WHERE status_v2 IS NULL;

-- Mismatch monitor (during dual-write):
SELECT COUNT(*) AS mismatches
FROM event_attendance
WHERE status_v2 IS NOT NULL AND (
  (status_v2='checkedin' AND status NOT IN ('checkedin','attended','present')) OR
  (status_v2='dna' AND status NOT IN ('dna','noshow','no_show')) OR
  (status_v2='walkin' AND status NOT IN ('walkin','walk_in')) OR
  (status_v2='preregistered' AND status NOT IN ('preregistered','registered'))
);
```

## Rollback
- Keep toggles to revert read pivot; restore legacy writes temporarily if needed.

Rollback steps:
1) Set `status_v2_read_pivot=false` to fall back to legacy read path.
2) Re-enable legacy writes (set `status_v2_dual_write=true`).
3) Investigate mismatches; correct and re-run backfill for bad rows.
4) Repeat verification, then re-attempt pivot.

Post‑migration hardening:
- Add NOT NULL constraint on `status_v2` once backfill verified (for SQLite, enforce at app level or rebuild table with constraint).
- Ensure new writes only accept canonical codes (`preregistered|walkin|checkedin|dna`).
