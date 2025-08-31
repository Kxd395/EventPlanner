# Swift + Rust Architecture Plan (EventDeskPro)
Last Updated: 2025-08-29 23:15:47Z

## Goals
- Centralize business logic (status machine, CSV, analytics, migrations) in Rust.
- Expose type‑safe APIs to Swift via FFI.
- Keep UI reactive and optimistic; Rust enforces validation.

## Rust Core (`eventdesk_core`)
- Domain: Member, Event, Attendance, AttendeeStatus(`preregistered|walkin|checkedin|dna`).
- Services:
  - Status transitions: validation + audit reason rules + auto‑rollover.
  - CSV: preview (dedupe, mapping, errors), commit (partial success).
  - Analytics: enqueue events, PII envelope separation.
  - Persistence: SQLite migrations & queries (rusqlite/sqlx), feature flags.
- FFI:
  - Option A: `uniffi` to generate Swift bindings.
  - Option B: `cbindgen` C‑header + Swift modulemap.
- Build: `cargo build --release` → static/dylib for macOS (universal via lipo if needed).

## Swift Integration (SwiftUI macOS)
- Package structure: App target + a thin Data layer calling Rust.
- Async calls: wrap FFI in `Actor`/`ObservableObject` for main‑thread UI.
- Optimistic UI: apply local state first; reconcile with Rust result or roll back.
- Error handling: typed errors from Rust mapped to Swift enums.

## API Surface (FFI)
- listEvents(), getEvent(eventId)
- listAttendance(eventId, filters)
- updateStatus(attendanceId, newStatus, {reason?, managerOverride?, origin?})
- createWalkin(eventId, contact, {immediateCheckIn?})
- previewImport(eventId, csvBytes) → {previewId, totals, duplicates, errors}
- commitImport(previewId)
- emitAnalytics(name, context, payload, pii?)

## Database & Migration
- Migrations versioned in Rust crate; run at app startup.
- Dual‑write + backfill + pivot per SSOT.
- Guards to prevent legacy writes post‑pivot.

## Testing
- Rust: unit + integration for state machine, CSV, analytics.
- Swift: unit for view models; integration against FFI; minimal UI smoke.

## CI/CD (outline)
- Jobs: format/lint, build Rust, build Swift, run tests, package artifact.
- Quality gates: coverage ≥70% (Phase 1), lint clean, migration guard.

## Deployment (macOS)
- Build universal Rust lib (x86_64 + arm64) and link in Swift app.
- Code sign app + embedded libs; notarize; distribute DMG/ZIP.
- Keep privacy: analytics PII only inside `pii` payloads.
