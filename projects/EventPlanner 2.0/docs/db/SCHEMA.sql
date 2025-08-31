-- Canonical Schema (Aligned to docs/ssot/SSOT.md)

CREATE TABLE IF NOT EXISTS members (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  company TEXT,
  tags TEXT,
  notes TEXT,
  membership_tier TEXT DEFAULT 'attendee',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS events (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  starts_at DATETIME NOT NULL,
  ends_at DATETIME NOT NULL,
  location TEXT,
  capacity INTEGER,
  status TEXT,
  timezone TEXT DEFAULT 'UTC',
  description TEXT
);

CREATE TABLE IF NOT EXISTS event_attendance (
  id TEXT PRIMARY KEY,
  member_id TEXT NOT NULL REFERENCES members(id),
  event_id TEXT NOT NULL REFERENCES events(id),
  status TEXT NOT NULL CHECK(status IN ('preregistered','walkin','checkedin','dna')) DEFAULT 'preregistered',
  ticket_type TEXT,
  seat TEXT,
  source TEXT,
  checked_in_at DATETIME,
  event_notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(member_id, event_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_members_email ON members(email);
CREATE INDEX IF NOT EXISTS idx_event_attendance_event ON event_attendance(event_id);
CREATE INDEX IF NOT EXISTS idx_event_attendance_status ON event_attendance(status);
CREATE INDEX IF NOT EXISTS idx_event_attendance_member ON event_attendance(member_id);

CREATE TABLE IF NOT EXISTS status_audit_log (
  id TEXT PRIMARY KEY,
  attendance_id TEXT NOT NULL REFERENCES event_attendance(id),
  prior_status TEXT,
  new_status TEXT NOT NULL,
  reason TEXT,
  changed_by TEXT,
  changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS member_merge_log (
  id TEXT PRIMARY KEY,
  from_member_id TEXT NOT NULL REFERENCES members(id),
  to_member_id TEXT NOT NULL REFERENCES members(id),
  merged_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
-- Last Updated: 2025-08-29 23:15:47Z
