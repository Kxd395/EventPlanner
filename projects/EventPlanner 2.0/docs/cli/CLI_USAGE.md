# Developer CLI — edp_tool
Last Updated: 2025-08-29 23:15:47Z

The Rust core includes a small CLI for local workflows.

## Build
```
cd rust-core
cargo build --bin edp_tool --release
```

## Commands
- Preview CSV
```
target/release/edp_tool preview ../samples/csv/sample_attendees.csv
```

- Commit CSV to DB (creates/links members and event_attendance, writes audit log)
```
target/release/edp_tool commit evt_123 ../samples/csv/sample_attendees.csv --db /tmp/eventdesk.db
```

- Validate analytics JSON
```
target/release/edp_tool validate-analytics ../samples/analytics/valid_event.json
```

- Emit analytics JSON (appends to JSONL file)
```
target/release/edp_tool emit-analytics ../samples/analytics/valid_event.json --out /tmp/analytics.jsonl
```

- Export CSV for an event
```
target/release/edp_tool export evt_123 --db /tmp/eventdesk.db > attendees.csv
```

- Get counts by status for an event
```
target/release/edp_tool counts evt_123 --db /tmp/eventdesk.db
```

- Update an attendee status with validation
```
target/release/edp_tool update-status <attendanceId> checkedin --db /tmp/eventdesk.db --in-progress --changed-by cli
```

- List attendees for an event (JSON)
```
target/release/edp_tool list evt_123 --db /tmp/eventdesk.db
```

- Remove an attendee from an event
```
target/release/edp_tool remove-attendance <attendanceId> --db /tmp/eventdesk.db --reason "cleanup"
```

- Search members (global directory)
```
target/release/edp_tool search-members jane --db /tmp/eventdesk.db --limit 10
```

- Create a walk-in (optional immediate check-in)
```
target/release/edp_tool walkin --event evt_123 --name "John Doe" --email john@example.com --company Orbit --checkin --db /tmp/eventdesk.db
```

- Merge duplicate member into primary
```
target/release/edp_tool merge-members <primary_member_id> <duplicate_member_id> --db /tmp/eventdesk.db
```
- Create event
```
target/release/edp_tool event-create --name "Launch" --starts 2025-09-01T09:00:00Z --ends 2025-09-01T17:00:00Z --location "Center" --capacity 200 --status active --tz UTC --db /tmp/eventdesk.db
```

- List events
```
target/release/edp_tool events --db /tmp/eventdesk.db --limit 25 --offset 0
```
