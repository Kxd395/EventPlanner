# SQLite Setup — EventDeskPro (Aligned to SSOT v1.1 and Current Code)
Last Updated: 2025-08-29 23:15:47Z

This guide fits your existing code and schema (`SCHEMA.sql`) and avoids breaking changes. It adds ops best‑practices, optional extensions (views/FTS), and example queries. Status codes match the app and core: `preregistered`, `walkin`, `checkedin`, `dna`.

Related: `./SCHEMA.sql` (applied automatically), `rust-core/src/lib.rs` (connection pragmas), `../ssot/EVENTDESKPRO_SSOT.md` (logic + formulas)

## 1) Connection Pragmas (now enabled in core)
- foreign_keys=ON, journal_mode=WAL, synchronous=NORMAL, busy_timeout=5000
- Implemented in: `rust-core/src/lib.rs` open_conn()

## 2) Canonical Tables (already in place)
- members, events, event_attendance, status_audit_log, member_merge_log (see `SCHEMA.sql`)
- Status check constraint: `('preregistered','walkin','checkedin','dna')`

## 3) Optional: Analytics Views (Reg%, No‑show, Counts)
These do not change data; safe to add as a migration.

```
-- v_event_counts: per-event totals (keeps existing four statuses)
CREATE VIEW IF NOT EXISTS v_event_counts AS
SELECT
  e.id AS event_id,
  SUM(CASE WHEN ea.status IN ('preregistered','walkin','checkedin') THEN 1 ELSE 0 END) AS total_active,
  SUM(CASE WHEN ea.status='preregistered' THEN 1 ELSE 0 END) AS preregistered,
  SUM(CASE WHEN ea.status='walkin' THEN 1 ELSE 0 END) AS walkin,
  SUM(CASE WHEN ea.status='checkedin' THEN 1 ELSE 0 END) AS checkedin,
  SUM(CASE WHEN ea.status='dna' THEN 1 ELSE 0 END) AS dna,
  e.capacity
FROM events e
LEFT JOIN event_attendance ea ON ea.event_id = e.id
GROUP BY e.id;

-- Reg% = (Pre-Reg + Walk-in + Checked-In) / Capacity
CREATE VIEW IF NOT EXISTS v_event_reg_percent AS
SELECT
  event_id,
  CASE WHEN capacity > 0 THEN ROUND((preregistered + walkin + checkedin) * 100.0 / capacity, 1)
       ELSE 0 END AS reg_percent
FROM v_event_counts;

-- No-show Rate = DNA / (Pre-Reg + Walk-in)
CREATE VIEW IF NOT EXISTS v_event_noshow_rate AS
SELECT
  event_id,
  CASE WHEN (preregistered + walkin) > 0 THEN ROUND(dna * 100.0 / (preregistered + walkin), 1)
       ELSE 0 END AS noshow_percent
FROM v_event_counts;
```

## 4) Optional: FTS5 for Member Search
Adds fast search by name/email/phone. Only apply if your SQLite build has FTS5. Verify first:

```
PRAGMA compile_options; -- look for ENABLE_FTS5
```

Schema and sync triggers:
```
CREATE VIRTUAL TABLE IF NOT EXISTS members_fts USING fts5(
  first_name, last_name, email, phone, company, content='members', content_rowid='id'
);
CREATE TRIGGER IF NOT EXISTS trg_members_ai AFTER INSERT ON members BEGIN
  INSERT INTO members_fts(rowid, first_name,last_name,email,phone,company)
  VALUES (NEW.id, NEW.first_name,NEW.last_name,NEW.email,NEW.phone,NEW.company);
END;
CREATE TRIGGER IF NOT EXISTS trg_members_ad AFTER DELETE ON members BEGIN
  INSERT INTO members_fts(members_fts, rowid, first_name,last_name,email,phone,company)
  VALUES ('delete', OLD.id, OLD.first_name,OLD.last_name,OLD.email,OLD.phone,OLD.company);
END;
CREATE TRIGGER IF NOT EXISTS trg_members_au AFTER UPDATE ON members BEGIN
  INSERT INTO members_fts(members_fts, rowid, first_name,last_name,email,phone,company)
  VALUES ('delete', OLD.id, OLD.first_name,OLD.last_name,OLD.email,OLD.phone,OLD.company);
  INSERT INTO members_fts(rowid, first_name,last_name,email,phone,company)
  VALUES (NEW.id, NEW.first_name,NEW.last_name,NEW.email,NEW.phone,NEW.company);
END;
```

## 5) Helpful Indexes (most exist; add if missing)
```
CREATE INDEX IF NOT EXISTS idx_event_attendance_event ON event_attendance(event_id);
CREATE INDEX IF NOT EXISTS idx_event_attendance_status ON event_attendance(status);
CREATE INDEX IF NOT EXISTS idx_event_attendance_member ON event_attendance(member_id);
CREATE INDEX IF NOT EXISTS idx_members_email ON members(email);
```

## 6) Example Queries (UI wiring)
- Dashboard rows with Reg%:
```
SELECT e.id, e.name, e.capacity, r.reg_percent
FROM events e
LEFT JOIN v_event_reg_percent r ON r.event_id=e.id
ORDER BY e.starts_at DESC;
```
- No-show percent (single event):
```
SELECT noshow_percent FROM v_event_noshow_rate WHERE event_id = ?;
```
- Search (FTS version):
```
SELECT m.id, m.first_name, m.last_name, m.email, m.phone
FROM members_fts f JOIN members m ON m.id=f.rowid
WHERE members_fts MATCH ?
LIMIT 20;
```

## 7) Migrations & Safety
- Keep these in a separate SQL file (e.g., `docs/migrations/0002_views_fts.sql`).
- Apply inside a transaction with `PRAGMA foreign_keys=ON;`.
- Only add FTS if `ENABLE_FTS5` is present.

## 8) Encryption & Keys (optional)
- If you need DB at-rest encryption, use SQLCipher in the Rust build and keep keys in the Keychain. Do not hardcode secrets.

## 9) Settings & Future Columns (not required now)
- Future UX (Confirm ✔, VIP ⭐) can add columns to `event_attendance` (e.g., `confirmed INTEGER DEFAULT 0`, `is_vip INTEGER DEFAULT 0`). Adding columns is backward compatible; current code ignores unknown columns.

---

Implementation status
- Core now sets WAL/foreign_keys/busy_timeout (see `rust-core/src/lib.rs`).
- Base schema stays unchanged and compatible with existing code.
- Views/FTS are provided as optional migrations; safe to adopt when ready.
