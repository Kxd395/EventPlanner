# EventDeskProApp — GitHub Issues Seed
Last Updated: 2025-08-29 23:15:47Z

Related docs: [UI Spec (ASCII)](../ui/UI_SPEC_ASCII.md) · [Logic Mapping Prompt](../swift/SWIFT_APP_LOGIC_PROMPT.md) · [Progress](../progress/PROGRESS.md)

Copy the sections below into individual GitHub issues (one per section). Each includes a title, summary, concrete tasks, acceptance criteria, and suggested file references.

---

## [Dashboard] Registration % not updating

Summary: Events list shows 0% even when attendees exist. Ensure Reg% counts Pre-Registered + Walk-in + Checked-In, excludes DNA/Cancelled, and refreshes after updates.

- [ ] Normalize canonical status mapping for UI math
- [ ] Update Reg% and mini-bar to use Pre-Reg + Walk-in + Checked-In
- [ ] Exclude DNA (and future Cancelled) from totals
- [ ] Refresh counts immediately after attendee status updates
- [ ] Add unit/UI smoke for Reg% basic cases

Acceptance Criteria
- [ ] Given an event with preregistered=10, walkin=5, checkedin=3, capacity=100, the Reg% shows 18%
- [ ] Changing statuses updates the Reg% row within 1s without re-launch
- [ ] DNA attendees do not affect the Reg% numerator

File References
- `apps/EventDeskProApp/Sources/Views/Events/EventsListView.swift:112` (Reg% and ratio)
- `apps/EventDeskProApp/Sources/Views/Events/EventsListView.swift:134` (counts fetch)
- `Sources/EventDeskCoreBindings/EDPCore.swift:111` (StatusCounts/FFI)
- `apps/EventDeskProApp/Sources/Views/Attendees/AttendeesView.swift:233` (status change emit; publish refresh)

---

## [UI] Attendee status colors are unclear

Summary: Status chips/dots look dull/grey; map statuses to distinct colors that match SSOT.

- [ ] Map statuses (per SSOT): Pre-Registered → Blue, Walk-in → Purple, Checked-In → Green, DNA → Gray
- [ ] Update `EDPDesign` palette (add Amber/Red if needed)
- [ ] Apply `EDPDesign.color(for:)` consistently in list rows and chips
- [ ] Verify A11y contrast for text on tinted backgrounds

Acceptance Criteria
- [ ] Status chip and dot colors match the mapping across Attendees and Reports
- [ ] Color alone is not the only indicator (label still present)

File References
- `apps/EventDeskProApp/Sources/Design.swift:10` (status palette/mapping)
- `apps/EventDeskProApp/Sources/Views/Components/StatusChip.swift:41` (filter chips)
- `apps/EventDeskProApp/Sources/Views/Attendees/AttendeeRow.swift:11` (status dot)

---

## [Attendees] Confirmation and VIP tagging

Summary: Add a way to mark preregistrations as Confirmed and star VIPs/speakers/staff; show badges in list and reports.

- [ ] Extend schema (core/FFI) with `confirmed` bool on attendance; `is_vip` on member or event-participant link
- [ ] Bindings: expose confirm/star update APIs in EDPCore
- [ ] UI: add Confirm ✔ and Star ⭐ toggles in AttendeeDetailPanel and row context menu
- [ ] Display badges in attendee row and include in exports/reports

Acceptance Criteria
- [ ] Confirm and Star states persist and reflect after reload
- [ ] Filters/search can include Confirmed/VIP

File References
- `apps/EventDeskProApp/Sources/Views/Attendees/AttendeeDetailPanel.swift:14` (panel content)
- `apps/EventDeskProApp/Sources/Views/Attendees/AttendeeRow.swift:13` (badges next to name)
- `Sources/EventDeskCoreBindings/EDPCore.swift` (add APIs)
- `rust-core/src/lib.rs` (schema + audit logging)

---

## [Data Model] Global Member Directory vs Event Participants

Summary: Avoid duplicate contacts by maintaining a global members table (unique by email/phone) and an event-participants table with per-event status/history.

- [ ] Enforce uniqueness by email/phone in members (nullable-friendly)
- [ ] Auto-create global member for transient attendees (`is_transient=true` flag)
- [ ] Ensure event participants link to global members; dedupe on import/walk-in
- [ ] Add merge tooling confirmation in UI (already have merge; surface affordances)

Acceptance Criteria
- [ ] Importing a CSV with a duplicate email links to the same member across events
- [ ] Walk-in without email creates a transient member; adding email later dedupes

File References
- `rust-core/src/lib.rs` (constraints, import/walk-in, merge members)
- `Sources/EventDeskCoreBindings/EDPCore.swift:147` (member search; extend as needed)
- `apps/EventDeskProApp/Sources/Views/Attendees/CSVImportView.swift` (import flow)

---

## [Settings] Enhance customization

Summary: Improve Settings to support status colors, default initial status, DNA timeout, auto-confirm messaging, directory sync, and custom statuses.

- [ ] Add color pickers for status colors; persist via AppStorage or core config
- [ ] Default initial status selector (Pre-Reg/Walk-in/Checked-In)
- [ ] Auto-mark DNA after X minutes (core timer/rollover setting)
- [ ] Toggles: auto-send confirmation email/SMS; sync new attendees to directory
- [ ] Custom statuses (design + SSOT: mapping to canonical or extend schema)

Acceptance Criteria
- [ ] Settings persist across relaunch
- [ ] Changing a setting affects UI/logic without manual restart (where feasible)

File References
- `apps/EventDeskProApp/Sources/Views/Settings/SettingsView.swift:11` (settings form)
- `apps/EventDeskProApp/Sources/Design.swift` (status colors)
- `Sources/EventDeskCoreBindings/EDPCore.swift` (config surface, if centralized)

---

## [Reports] Replace placeholders with charts

Summary: Implement Check-in Curve, No-show Rate, and a Conversion Funnel; show totals and color-coded chips.

- [ ] Add time-bucketed check-in series API (core/FFI) and Swift binding
- [ ] Compute No-show Rate = DNA / Pre-Reg
- [ ] Conversion funnel: Pre-Reg → Confirmed → Checked-In
- [ ] Render charts (simple SwiftUI shapes or a lightweight chart lib)

Acceptance Criteria
- [ ] Charts render for non-empty data and handle empty states
- [ ] Colors match status palette; totals visible as chips

File References
- `apps/EventDeskProApp/Sources/Views/ReportsView.swift:21` (placeholders)
- `Sources/EventDeskCoreBindings/EDPCore.swift` (add analytics APIs)
- `rust-core/src/lib.rs` (aggregation queries)

---

## [QoL] Quick actions, search expansion, audit trail, capacity warnings

Summary: Add right-click quick actions, expand search, add per-attendee audit timeline, and warn when registrations exceed capacity.

- [ ] Context menu: Check-In, Mark DNA, Send Email, Star
- [ ] Expand attendee search (consider phone) — may require schema additions
- [ ] Per-attendee audit timeline (status changes with timestamps)
- [ ] Capacity warning when Reg% exceeds capacity (banner or inline warning)

Acceptance Criteria
- [ ] Context actions operate without opening detail panel
- [ ] Search finds by name/company/email (and phone if present)
- [ ] Audit panel shows last N status changes
- [ ] Warning appears when registrations > capacity

File References
- `apps/EventDeskProApp/Sources/Views/Attendees/AttendeesView.swift:74` (context menu hooks)
- `apps/EventDeskProApp/Sources/Views/Attendees/AttendeesView.swift:177` (search fields)
- `apps/EventDeskProApp/Sources/Views/Attendees/AttendeeDetailPanel.swift` (timeline section)
- `apps/EventDeskProApp/Sources/Views/Events/EventsListView.swift:112` (capacity/Reg% for warnings)
- `rust-core/src/lib.rs` (audit log queries)
