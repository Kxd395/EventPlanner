# EventDeskPro — Logic & Flow SSOT (v1.1)
Last Updated: 2025-08-29 23:15:47Z

Scope: This document consolidates and supersedes UI_SPEC_ASCII.md, ISSUES_CHECKLIST.md, and SWIFT_APP_LOGIC_PROMPT.md into a single, authoritative reference for the Swift/iOS/macOS implementation of EventDeskProApp. It resolves identified contradictions (e.g., color mappings, analytics formulas), fills gaps (e.g., missing buttons, flows, functions from issues like VIP tagging and audit trails), and incorporates best practices (e.g., MVVM architecture, security considerations, testing). Version history tracks changes; this is v1.1 (updated for clarity, added security/privacy section, refined QA checklist, and included command palette from original improvements). Use this as the SSOT—any spec changes must update this file via approved PRs.

Related docs: [UI Spec (ASCII)](../ui/UI_SPEC_ASCII.md) · [Issues Checklist](../issues/ISSUES_CHECKLIST.md) · [Logic Prompt](../swift/SWIFT_APP_LOGIC_PROMPT.md) · [Progress](../progress/PROGRESS.md)

## Architecture Notes (Best Practices)
- MVVM Pattern: Use Models (from Rust FFI via EDPCore.swift), ViewModels (business logic, e.g., status updates), and Views (SwiftUI presentation). Decouple UI from core for testability.
- Data Handling: Offline-first with local persistence (SQLite via Rust core); queue actions for sync. Validate inputs client-side. Use async/await for FFI calls; handle errors with custom enums.
- Security & Privacy: Authenticate users (roles: admin/staff); role-based access (e.g., managers for overrides). Encrypt PII (Keychain/SQLite encryption). Audit all changes. Comply with GDPR/CCPA—add consent toggles. No analytics without opt-in.
- Performance: Lazy-load lists; pagination for large sets; cache searches.
- Testing: ≥80% coverage—unit (formulas), UI (flows), snapshots. CI via GitHub Actions.
- Internationalization: NSLocalizedString; RTL, Dynamic Type, locale/timezones.
- Extensibility: Custom statuses map to canonical (e.g., new status inherits from Pre-Reg); persist in settings.

## 1. Page Inventory
- Dashboard (Events List); Attendees Tab; Attendee Detail Drawer; Add Attendee; Walk-in Registration; Reports & Analytics; Settings; CSV Import/Export; Global Member Profile; Error/Loading/Empty States; Shortcuts Overlay; Command Palette (⌘⇧P).

## 2. Buttons & Actions (Complete)
Each button includes trigger, logic, and outcome. All actions emit audit logs and refresh relevant views (via ViewModels/publishers).

- Dashboard: +New Event; Row Open/Edit/Delete; Capacity Warning banner (>100%).
- Attendees: +Add; Walk-in; Import CSV; Export CSV; Send Emails; Bulk: Select All/Checked-In/DNA/Remove; Row context menu quick actions.
- Detail Drawer: Status toggles; Confirm ✔; Star ⭐; Open Member Profile; Remove; Save Changes.
- CSV Preview: Preview; Download Errors CSV; Commit.
- Settings: Org name/timezone/theme; Status colors; Defaults; DNA timeout; Directory sync; Notifications.
- Reports: Check-in Curve; No-show Rate; Conversion Funnel; Export.
- Command Palette: Search and execute primary actions.

## 3. Navigation Flow
- Events → Event Detail (tabs: Overview, Attendees, Schedule, Assets, Settings, Reports).
- Attendees → Drawer/Profile; Modals (Add, Walk-in, Import); Back restores scroll/anchor.

## 4. Logic Table (Abbreviated)
| Screen | Component | Trigger | Function | Outcome |
|--------|-----------|---------|----------|---------|
| Attendees | Mark DNA | Button | FFI bulkStatusUpdate(new: dna) with checks | Rows updated; counts refresh |
| Attendees | Undo | Toast action | FFI bulkStatusUpdate(prior) override | Reverts change; audit logged |
| CSV | Commit | Button | FFI csvCommit(eventId,text) | Members linked/created; audit |

## 5. Metrics & Formulas
- Reg% = (Pre-Reg + Walk-in + Checked-In) / Capacity; excludes DNA and Cancelled.
- No-show Rate = DNA / Pre-Registered (option: include Walk-in only if registered onsite).

## 6. Colors (Authoritative)
- Pre-Registered: #2563eb (Blue)
- Walk-in:        #8b5cf6 (Purple)
- Checked-In:     #16a34a (Green)
- Did Not Attend: #6b7280 (Gray)

## 7. Accessibility & Shortcuts
- Contrast ≥4.5:1; labels/icons augment colors. Focus order logical; no traps. Shortcuts: /, ?, N, A, W, Esc, ⌘⇧P.

## 8. Contradictions Resolved
- Colors fixed to Blue/Purple/Green/Gray.
- Metrics standardized; Cancelled excluded.
- Canonical statuses fixed; custom statuses map to canonical.

## 9. QA Checklist
- Every screen has ≥1 actionable element; all buttons mapped trigger→logic→outcome.
- State machine enforced; analytics formulas validated; colors/contrast checked.
- Navigation covers all screens; CSV import preview dedupes; settings persist; reports handle empty/non-empty.
- Security: role checks; PII encrypted; opt-in analytics.
- Tests: unit/UI/i18n; performance acceptable for large lists; offline mode functional.

Note: Treat this as the living SSOT. Changes require PRs updating this file, plus corresponding updates to UI spec and issues.
