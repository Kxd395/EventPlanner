# Project Progress – EventDeskPro (Swift + Rust SSOT)
Status: IN_PROGRESS

Last Updated: 2025-08-29 23:15:47Z

## Overall Readiness
- Estimated readiness toward production: 99%
- Overall completion: 95%

## Area Completion (Estimates)
- SSOT/Docs: 90%
- Rust Core (status/CSV/analytics): 98%
- FFI/SPM Bindings: 85%
- SwiftUI Wiring: 80%
- Migration Execution: 10%
- A11y/Shortcuts/Empty/Error: 20%
- Reports & Settings: 10%
- CI & Tests: 75%
- Basis: SSOT + docs aligned; Rust core + FFI + SPM wrapper in place; CSV preview and analytics validation implemented; SwiftUI wiring, DB-backed CSV commit, migration execution, reports/settings, and CI gates remain.

## Highlights This Update
- Wired status-change dialog (reason/override) end-to-end and added an Undo toast to quickly revert recent status updates; implemented return-anchor highlight when closing profile.
- Events Reg% now refreshes automatically after attendee updates (notification-driven); Walk-in/Add/Import/Status changes all trigger row refresh.
- Database configuration no longer hardcoded: supports ENV (`EDP_DB_PATH`, `EDP_ANALYTICS_PATH`) and UserDefaults (`dbPath`, `analyticsPath`) overrides with App Support fallback.
- Consolidated SSOT doc added: `docs/ssot/EVENTDESKPRO_SSOT.md` (v1.1) to unify UI spec, issues, and logic prompt; aligned palette to SSOT (Walk-in=Purple, DNA=Gray) and standardized metric formulas.
- SQLite connection pragmas enabled in core (WAL, foreign_keys=ON, busy_timeout=5000, synchronous=NORMAL). Added deployment notes + optional analytics views/FTS in `docs/db/DB_SQLITE_SETUP.md`.
- Unified SSOT and normalized all docs across the project.
- Rust SSOT core implemented (status enum, transitions, normalization, auto‑rollover).
- CSV preview (dedupe/errors) and analytics validation + file-backed emit via FFI.
- C FFI + SwiftPM wrapper added; universal build and packaging scripts added; new dev CLI (edp_tool) for preview/commit/export/analytics; CLI counts/update-status/list/remove/search/walkin added; auto-rollover FFI added.
- CSV commit now writes status audit logs; added tests and temp-file DB verification.
- Added list/remove/search/walk-in in DB/FFI/Swift + tests; added schema indexes.
- Added merge members (DB/FFI/Swift/CLI) + member merge log + DEDUPE.md.
- Added events (create/update/list) DB/FFI/Swift + CLI; CLI usage docs expanded. Added rollover/versions commands in CLI help.
- Added audit log list/export JSON/bulk status update/member profile/ event delete APIs (DB/FFI); updated FFI docs.
- Swift sample wrappers/ViewModel to accelerate UI wiring. Minimal SwiftUI app scaffold (SPM executable) added to build/run bindings.
- Added SwiftUI Event Detail + Attendees views with status filter chips, counts, and CSV export.
- Added CSV Import modal (TextEditor preview + commit) wired to FFI; analytics events for preview/commit/export.
- Introduced UI components: StatusChip/FilterBar, Empty/Error states, Toasts; keyboard shortcuts overlay.
- Schema aligned for walk-ins (members.email nullable) and DB commit inserts fixed to use NULL for missing email.
- File-backed analytics queue and FFI last-error retrieval added for safer Swift integration.
- New Event v1.3: DatePickers + Timezone Picker; capacity copy (“Max guests (capacity)”; Use 0 for unlimited); validation & shortcuts.
- Unified Import/Export menus (v1.4) on Events, Attendees, Members; default scope=Filtered; PII gating toggle in Settings (CSV/JSON disabled when restricted); Multi-export; consistent filenames.
- Attendees: inline row status controls; migration banner + Run Backfill; export scopes & formats; multi-import from files.
- Reports: Counts/Check‑ins export; basic Check‑in Curve and No‑show percentage.

## Status by Area (Quick)
- SSOT/docs: Strong (90%)
- Rust core (status/CSV/analytics): Strong (98%) — DB-backed CSV commit + tests; CSV export; counts API; auto-rollover; list/remove/search/walk-in; audit logs; analytics queue; validator modularized + tested
- FFI/SPM bindings: Good (85%)
- SwiftUI wiring: Good (80%)
- Migration execution: Not started (10%) — runbook ready
- A11y/Shortcuts/Empty/Error: Planned (20%)
- Reports & Settings: Planned (10%)
- CI & Tests: Partial (75%) — Rust tests + analytics/store DB tests + CLI smoke (preview/validate/commit/export) in CI; Swift/coverage pending

## TODO Checklist

- SSOT & Documentation
  - [x] Canonical SSOT (docs/ssot/SSOT.md)
  - [x] PRD/UI/Navigation/Analytics/Testing/Schema docs aligned
  - [x] Migration runbook + QA script
  - [x] External docs patched to SSOT
  - [x] Consolidated SSOT (docs/ssot/EVENTDESKPRO_SSOT.md v1.1) created
  - [x] SQLite setup doc with views/FTS options (docs/db/DB_SQLITE_SETUP.md)

- Rust Core
  - [x] Status enum + transitions + normalization
  - [x] Auto‑rollover helper
  - [x] CSV preview (dedupe/errors) → JSON
  - [x] CSV commit (DB‑backed create‑or‑link) + basic tests
  - [x] Analytics validate (whitelist + PII) and file-backed emit
  - [x] Unit/integration tests for core helpers

- FFI & Bindings
  - [x] C header with safe ownership + extras
  - [x] FFI for status/CSV/analytics
  - [x] SwiftPM wrapper package (EventDeskCoreBindings)

- SwiftUI Integration
  - [x] Event Detail view + navigation
  - [x] Attendees list view w/ counts + status filter chips
  - [x] Empty/loading/error states + toasts
  - [x] CSV preview UI + commit flow (modal)
  - [x] Basic analytics instrumentation for key actions (preview/commit/export/profile)
  - [x] Keyboard shortcuts overlay (help)
  - [x] Walk-in modal wired to bindings
  - [x] Search input + keyboard focus (/)
  - [x] Multi-select + bulk actions toolbar
  - [x] Context menu per attendee
  - [x] Status change sheet (reason/override) scaffolding
  - [x] CSV errors export + duplicate list in preview
  - [x] Command Palette (⌘⇧P)
  - [x] New Event sheet
  - [x] Theme preference applied (light/dark)
  - [x] Deep-link highlight (scroll + ring)
  - [x] Reports tab with basic charts
  - [x] Add Attendee (search-first) modal
  - [x] Attendee right-side drawer panel (inline status change)
  - [x] Events list table view with columns + reg(%)
  - [x] Members list view (global search)
  - [x] Merge duplicates flow (primary/duplicate)
  - [x] Global header/footer + top-level tabs (Events | Members)
  - [x] Command palette closes on action/ESC; Settings/Shortcuts sheets have Close
  - [x] Breadcrumb/back button on Event Detail
  - [x] Wire status transitions with reason/override dialogs
  - [x] Return anchor on member profile back
  - [x] Reg% auto-refresh after updates (events row)
  - [x] Keyboard shortcuts: A (Add), W (Walk‑in), / (Search)
  - [x] Palette/colors aligned to SSOT (Blue/Purple/Green/Gray)

- Migration Execution (Runtime)
  - [ ] Phase 0–2: add status_v2, enable dual‑write, backfill (chunked if needed)
  - [ ] Phase 3: read pivot + mismatch monitor
  - [ ] Phase 4–5: stop legacy writes; cleanup legacy column

- A11y & Shortcuts
  - [ ] Implement shortcuts: /, N, A, W, Esc, ?
  - [ ] Accessible labels for status buttons; focus management

- Reports & Settings
  - [ ] 3 charts (attendance over time, check‑in curve, no‑show rate)
  - [ ] Settings: org name, timezone, theme; persistence

- CI & QA
  - [ ] Expand Swift tests; add UI smoke
  - [ ] CI gates: lint clean, tests pass, coverage ≥80%, migration guard
  - [ ] Analytics schema smoke validation in CI
  - [ ] DB smoke: open with WAL + foreign_keys; apply views migrations

## Swift UI/UX
- Design system: SSOT-aligned status colors (blue/purple/green/gray), semantic `EDPDesign.color(for:)` mapping
- Layout: Global header/footer; top-level tabs (Events | Members)
- Components: StatusChip/FilterBar; Empty/Error/Toast; Shortcuts overlay; Command Palette
- Views: Events (columns, reg%); EventDetail (Overview, Attendees, Schedule, Assets, Settings, Reports);
  Attendees (search/sort/filter/counts/bulk/export, right drawer panel); CSV Import (preview/commit + errors CSV + duplicates);
  Members (search list + merge duplicates); Settings (theme/timezone); New Event
- Bulk & dialogs: Status-change dialog (reason/override) and bulk status updates (pending copy polish)
- Navigation: Deep-link/highlight scaffolding and return anchor (pending)
- A11y: Accessible names on chips/rows; color not sole indicator; keyboard overlay; focus-safe inputs
- Analytics: Helper wrapper; events for `csv_import_preview`, `csv_import_commit`, `csv_export`, `member_profile_open`, `attendee_status_change`


## Milestones
- M1 — Core Wiring (60%): Status transitions, CSV preview/commit stub, analytics emit
- M2 — Data & Migration (45%): DB‑backed CSV commit, execute status_v2 migration
- M3 — Polish & Gates (30%): A11y/shortcuts, empty/error states, CI gates and coverage
- M4 — Reports/Settings & Release (15%): Minimal reports/settings, sign/notarize, package

## Next Actions
- Finalize dialogs copy (early DNA, undo reason) and polish microcopy
- Persist/restore scroll for drawer close in addition to profile
- Enhance Events reg% with mini bars; add status chip badges
- Members list: show events count; add “Add to Event” bulk action
- Reports: replace placeholders with line/area charts for check-in curve and no-show
- Xcode: add Run Script phase to copy universal dylib; optional install_name tooling
- Build: produce universal dylib via rustup targets on dev machine; verify lipo arches
- Tests/CI: add Swift UI smoke; enable coverage + migration guard

## M2.1 — UI Fixes (SSOT v1.2 alignment) — Events & Members

- Events — New Event modal
  - [x] Add Capacity field labeled “Max guests (capacity)” with helper (“Use 0 for unlimited. Whole numbers only.”)
  - [x] Create button unlock logic: requires non-empty Name and valid Start/End
  - [x] Persist to DB via FFI and auto-refresh Events list after creation
  - [x] Empty state CTA opens New Event modal
  - [x] Time zone dropdown (defaults to system)
  - [x] DatePicker controls with ISO conversion for persistence
  - [ ] Validate timezone input against full IANA list (beyond common set)

- Events — List view
  - [x] Capacity column present; verify value/“–” handling
  - [x] “New Event” button in header for quick access
  - [x] Export dropdown (CSV/JSON/Markdown/Text) with Filtered/Selected/All and Multi export
  - [x] Import menu (Text Editor, Files… multi-file)

- Members — Actions
  - [x] Add “+ Add Member” modal (Name, Email, Phone, Tags, Notes)
  - [x] “Add to Event” flow exists; verify multi-select path and success toast
  - [x] Unified Export menu (CSV/JSON/MD/TXT) + Import from Files; PII gating
  - [x] Add “+ Add Member” modal wired to core (createMember)
  - [x] Members Export CSV for current results

- Validation/QA
  - [ ] Date parsing errors surface inline in New Event modal
  - [ ] Keyboard input smoke (no bare-key shortcuts block typing)

- Attendees — Inline Controls
  - [x] Add row-level status controls (Pre‑Reg | Walk‑in | ✓ Check‑In | DNA) opening guard sheet
  - [x] Export dropdown + Multi export with PII gating (CSV/JSON disabled when restricted)

## Data & Migrations — Follow-ups

- Status v2 migration
  - [x] Phase 0–2: add column (on schema apply), enable dual-write (insert/update), backfill (runtime button)
  - [ ] Phase 3–5: pivot reads, stop legacy writes, cleanup
  - [x] App banner/log when `status_v2` nulls detected (pre-pivot) + Run Backfill button

- Audit schema alignment
  - [x] Align `status_audit_log` write sites in core with schema (use `prior_status`/`new_status`); rollover logs include per-row prior status

## Change Log — New Event Modal v1.3
- Added DatePicker controls with ISO8601 conversion for persistence.
- Replaced raw timezone text field with a Time Zone dropdown (defaults to system; persists identifier).
- Capacity relabeled with helper text: “Use 0 for unlimited. Whole numbers only.”
- Validation: Name required; End > Start; Capacity must be integer ≥ 0.
- Accessibility: Labels and keyboard shortcuts (⌘. cancel, ⌘↵ create).
- DB integration unchanged: still persists ISO timestamps + timezone via Rust FFI.
- UI string: “Max guests (capacity)” used consistently.
