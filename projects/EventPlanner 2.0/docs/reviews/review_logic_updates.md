# EventDeskPro — Logic & Flow SSOT (v1.5)
Last Updated: 2025-08-29T23:59:00Z

This supersedes UI_SPEC_ASCII.md, ISSUES_CHECKLIST.md, and SWIFT_APP_LOGIC_PROMPT.md as the single source of truth for EventDeskPro (macOS/iOS). All changes to behavior/labels/flows must update this doc via PR.

0) What changed since v1.1 (highlights)
• New Event modal: explicit “Max guests (capacity)” field with helper copy “Use 0 for unlimited. Whole numbers only.” Time zone is a Picker (IANA IDs), not a free‑text UTC string.
• Unified menus: Import and Export are dropdowns on Events, Attendees, Members (and optional Reports). Formats: CSV, JSON, Markdown (.md), TXT. Scope: All / Filtered / Selected. Filenames: context_YYYY-MM-DD_entity.ext. Role gating: CSV/JSON can be grayed out if user lacks PII export rights.
• Attendee editor = 2 cards: Contact (Global) and Participation (Event‑specific) with Member, ⭐ VIP, Walk‑in flag, Confirmed, status, timestamps, notes, and auto‑DNA timer (inherit event default or per‑attendee override).
• Capacity surfacing: Attendees tab shows capacity progress (“X / Max guests” or “Unlimited”) and uses the same wording app‑wide.
• Badges on rows: ⭐ VIP, 🏷 Member, ⚡ Walk‑in, ☑︎ Confirmed (in addition to status color).
• Analytics: confirmed formulas, capacity=0 means unlimited (no denominator cap).
• Appendix: Build/FFI quick triage for exit code 9 (linking/runpath/codesign) kept for devs.

# EventDeskPro — Logic & Flow SSOT (v1.1)
Last Updated: 2025-08-29 23:15:47Z

**Scope**: This document consolidates and supersedes **UI_SPEC_ASCII.md**, **ISSUES_CHECKLIST.md**, and **SWIFT_APP_LOGIC_PROMPT.md** into a single, authoritative reference for the Swift/iOS/macOS implementation of EventDeskProApp. It resolves identified contradictions (e.g., color mappings, analytics formulas), fills gaps (e.g., missing buttons, flows, functions from issues like VIP tagging and audit trails), and incorporates best practices (e.g., MVVM architecture, security considerations, testing). Version history tracks changes; this is v1.1 (updated for clarity, added security/privacy section, refined QA checklist, and included command palette from original improvements). Use this as the SSOT—any spec changes must update this file via approved PRs.

1) Architecture & Principles (no change)
- **MVVM Pattern**: Use Models (from Rust FFI via EDPCore.swift), ViewModels (business logic, e.g., status updates), and Views (SwiftUI presentation). Decouple UI from core for testability.
- **Data Handling**: Offline-first with local persistence (e.g., SQLite via Rust core); queue actions for sync. Validate inputs client-side (e.g., email regex). Use async/await for FFI calls; handle errors with custom enums.
- **Security & Privacy**: Authenticate users (e.g., login flow with roles: admin/staff); role-based access (e.g., managers for overrides). Encrypt PII (Keychain/SQLite encryption). Audit all changes. Comply with GDPR/CCPA—add consent toggles for emails/SMS. No analytics without opt-in.
- **Performance**: Lazy-load lists (SwiftUI List with pagination for 1000+ attendees); cache searches. Profile with Instruments.
- **Testing**: 80% coverage—unit (XCTest for formulas), UI (XCUITest for flows), snapshots. CI/CD via GitHub Actions.
- **Internationalization**: Use NSLocalizedString; support RTL, Dynamic Type, locale-based dates/timezones.
- **Extensibility**: Custom statuses map to canonical (e.g., new status inherits from Pre-Reg); persist in settings.

2) Time & Timezone (standard)
• Timezone control: IANA identifier Picker everywhere a TZ is set/edited. Default to system; include UTC and common regions. Persist the IANA ID. Warning if unknown ID (save rules per policy). Display human dates with tz short name; ISO‑8601 for storage/exports.

3) Pages (inventory)
- **Dashboard (Events List)**: Overview of events with Reg% mini-bars.
- **Attendees Tab**: List with filters, search, sorting, status chips.
- **Attendee Detail Drawer**: Right panel for editing/viewing.
- **Add Attendee (Search-first)**: Modal for searching/creating.
- **Walk-in Registration**: Minimal modal for quick adds.
- **Reports & Analytics**: Charts and summaries.
- **Settings**: App-wide customizations.
- **CSV Import/Export**: Preview modals.
- **Global Member Profile**: View/edit global contact (deduped by email/phone).
- **Error/Loading/Empty States**: Overlays/placeholders (cross-cutting).
- **Shortcuts Overlay**: Global help modal.
- **Command Palette**: Quick actions search (⌘⇧P, from improvements).

4) Buttons & Actions (canonical)
Each button includes trigger, logic, and outcome (per SWIFT_APP_LOGIC_PROMPT.md template). All actions emit audit logs and refresh relevant views (e.g., via @Published in ViewModels).

### Dashboard
- **[ + New Event ]**: Trigger: Tap. Logic: Open creation form; validate fields (name, date, capacity). Outcome: Add event to list; navigate to it.
- **Event Row Actions (Open/Edit/Delete)**: Trigger: Tap row/swipe. Logic: Open → load tabs; Edit → modal form; Delete → confirm dialog, cascade remove participants. Outcome: Update list; refresh counts.
- **Capacity Warning Banner**: Trigger: Auto when Reg% > 100%. Logic: Compute from analytics. Outcome: Show inline alert; dismiss on resolution.

### Attendees Tab
- **[ + Add Attendee ]**: Trigger: Tap. Logic: Open search-first modal. Outcome: Add to list; update counts.
- **[ 👋 Walk-in ]**: Trigger: Tap. Logic: Open minimal form. Outcome: Add as Walk-in; optional immediate check-in.
- **[ Import CSV ]**: Trigger: Tap. Logic: File picker → preview (totals, valid, duplicates, errors); dedupe by email/phone. Outcome: Commit adds/links; downloadable errors CSV.
- **[ Export CSV ]**: Trigger: Tap. Logic: Generate from filtered list (include statuses, timestamps). Outcome: Download/share file.
- **[ ✉ Send Emails ]**: Trigger: Tap (bulk/selected). Logic: Compose via MFMailComposeViewController; respect opt-outs. Outcome: Sent confirmation/reminders.
- **Bulk Actions ([ ☐ Select All ], [ Mark Checked-In ], [ Mark DNA ], [ Remove ])**: Trigger: Selection + tap. Logic: Confirm dialog (override for early DNA); update statuses in batch via FFI. Outcome: Refresh list; log changes.
- **Context Menu (Row-level: Check-In, DNA, Confirm, Star, Email, Remove)**: Trigger: Long-press/right-click. Logic: Quick status toggle or action without drawer. Outcome: Inline update; refresh row.

### Attendee Detail Drawer
- **Toggle Status ([Pre-Reg] [Walk-in] [✓ Check-In] [DNA])**: Trigger: Tap. Logic: Follow state machine; timestamp; optional confirm/override. Outcome: Update chip/color; emit refresh.
- **[ Confirm ✔ ]**: Trigger: Toggle (for Pre-Reg). Logic: Set confirmed bool; optional notification. Outcome: Badge in row; update funnel.
- **[ Star ⭐ ]**: Trigger: Toggle. Logic: Set is_vip on participant/member. Outcome: Badge in row; filterable.
- **[ Open Member Profile ]**: Trigger: Tap. Logic: Load global member (deduped). Outcome: Navigate to profile view.
- **[ Remove from Event ]**: Trigger: Tap. Logic: Confirm; unlink participant. Outcome: Remove from list; update counts (keep global member).
- **[ Save Changes ]**: Trigger: Tap. Logic: Validate form; commit via FFI. Outcome: Close drawer; refresh row.
- **Timeline Panel**: Trigger: Auto-load/expand. Logic: Query audit history (timestamps, changes). Outcome: Display list of events.

### Add Attendee
- **Search Existing ([Search])**: Trigger: Enter query (email/name/phone). Logic: Fuzzy search global members. Outcome: List results with [ Select ] buttons.
- **Create New Form Fields**: Trigger: No results/fallback. Logic: Validate required (* fields); auto-create transient member if no email. Outcome: Add to event/global.
- **Initial Status Radio**: Trigger: Select. Logic: Set default per settings. Outcome: Apply on add.
- **[x] Send Confirmation**: Trigger: Toggle. Logic: Queue email/SMS post-add. Outcome: Sent if checked.
- **[ Add Attendee ] / [ Cancel ]**: Trigger: Tap. Logic: Commit or dismiss. Outcome: Update list or close.

### Walk-in Registration
- **Minimal Form Fields**: Trigger: Input. Logic: Validate name; optional others. Outcome: Ready for register.
- **[ Quick Register ] / [ Register & Check-In ]**: Trigger: Tap. Logic: Add as Walk-in; optional immediate check-in + timestamp. Outcome: Add to list; update counts.

### Reports
- **Chart Tabs (Check-in Curve, No-show Rate, Conversion Funnel)**: Trigger: Switch tabs. Logic: Query aggregated data via FFI (time-buckets, rates). Outcome: Render charts (SwiftUI shapes or Charts framework).
- **Export Charts (CSV/PNG)**: Trigger: Tap. Logic: Generate data/image. Outcome: Download/share.

### Settings
- **Status Color Pickers**: Trigger: Select. Logic: Update palette; persist in AppStorage. Outcome: Hot-reload UI colors.
- **Default Initial Status Dropdown**: Trigger: Select. Logic: Persist; apply to new adds. Outcome: Update defaults.
- **DNA Auto-Timeout (Minutes)**: Trigger: Input. Logic: Set timer in core; auto-mark post-event. Outcome: Background job.
- **Toggles (Auto-Confirm, Sync Directory, Custom Statuses)**: Trigger: Toggle. Logic: Persist; enable features (e.g., custom → extend schema/UI). Outcome: Immediate effect where possible.
- **Theme & Timezone**: Trigger: Select. Logic: Update app theme; reflect in dates. Outcome: Reload views.

### Global Member Profile
- **Edit Fields (Name, Email, Phone, Company, Tags)**: Trigger: Input. Logic: Update global; propagate to linked events. Outcome: Sync across app.
- **Merge Duplicates**: Trigger: Detect/suggest. Logic: Confirm; combine records. Outcome: Deduped list.
- **[ Close ]**: Trigger: Tap. Logic: Save changes. Outcome: Return to prior view.

### Cross-Cutting
- **Command Palette (⌘⇧P)**: Trigger: Shortcut. Logic: Search actions (e.g., "Add Attendee"). Outcome: Trigger selected flow.
- **Shortcuts Overlay ([ ? ])**: Trigger: Shortcut. Logic: Display list. Outcome: Modal help.

## 3. Status State Machine
**Canonical Statuses** (enum in core):
- `preRegistered` (default for adds)
- `walkIn`
- `checkedIn`
- `didNotAttend` (DNA)
- `cancelled` (separate; excludes from metrics)

**Extensions**: Custom statuses via settings (map to canonical, e.g., "Speaker" → preRegistered + VIP).

**Transitions & Rules**:
- Pre-Reg → Confirmed (bool flag) → Checked-In
- Pre-Reg/Walk-in → Checked-In (timestamp)
- Any → DNA (override if event in progress; auto post-timeout)
- Any → Cancelled (confirm; remove from counts)
- Undo: Allowed for Check-In/DNA with required reason (logged).

**Side Effects**:
- Timestamps: checkedInAt, dnaAt.
- Notifications: Email/SMS for confirm/check-in (toggleable).
- Audit Trail: Log all changes (user, time, from/to).

## 4. Analytics & Formulas
All via FFI aggregations; real-time updates via observers.

- **Reg% (Dashboard)**: `(preRegistered + walkIn + checkedIn) / capacity * 100`. Excludes DNA/cancelled. Refresh <1s.
- **No-show Rate (Reports)**: `(DNA / (preRegistered + walkIn)) * 100`. Consistent denominator with Reg%.
- **Conversion Funnel**: Pre-Reg → Confirmed (%) → Checked-In (%).
- **Check-in Curve**: Buckets (e.g., 15-min) from event start; series of checkedInAt timestamps.
- **Empty Handling**: Graceful placeholders (e.g., "No data yet").

## 5. Navigation Flow
- Dashboard → Tap event → Tabs (Attendees/Reports/Settings)
- Attendees → Tap row → Drawer
- Attendees → Buttons → Modals (Add/Walk-in/Import)
- Drawer → [Open Member Profile] → Global Profile
- Global: Esc/Back restores prior scroll/tab.
- Deep Link: `/events/:id?tab=attendees&highlight=:attendeeId` → Scroll + highlight (500ms).
- Command Palette → Any action/flow.
- No dead ends: All modals have Cancel/Close.

## 6. Error/Empty/Loading
- **Empty**: "No attendees yet — [Add Attendee]" CTA.
- **Loading**: Spinner (⏳).
- **Error**: Banner (⚠️) + [Retry] / [View Logs] (audit/errors).

## 7. Accessibility & Shortcuts
- Contrast ≥4.5:1; labels/icons augment colors.
- Focus order logical; no traps.
- Shortcuts: / (search), ? (overlay), N (new event), A (add), W (walk-in), Esc (close), ⌘⇧P (palette).

## 8. Contradictions Resolved
- **Colors**: Fixed to authoritative spec (Blue Pre-Reg, Purple Walk-in, Green Checked-In, Gray DNA). Ignored issue suggestions (Amber/Red) to avoid fork.
- **Metrics**: Standardized formulas (include Walk-ins in no-show denominator; added Cancelled exclusion).
- **Statuses**: Canonical fixed + custom extensible (settings map to core).
- **DNA/Cancelled**: Distinct; Cancelled for preemptive removal.
- **Other**: Reg% excludes future Cancelled; import dedupes transients.

## 9. QA Checklist (Expanded for Dev & QA)
- [ ] Each screen has ≥1 actionable element (e.g., button).
- [ ] Every button has mapped trigger → logic → outcome; no TBD.
- [ ] Status machine enforced; invalid transitions blocked.
- [ ] Analytics match formulas in sample data (e.g., 10 Pre-Reg + 5 Walk-in = 15 numerator).
- [ ] Colors/contrast validated (e.g., via Simulator Accessibility Inspector).
- [ ] Navigation covers all screens; no dead ends (test back/esc).
- [ ] CSV import: Preview shows totals/errors/duplicates; dedupes work.
- [ ] Settings persist across relaunches; hot-reload (e.g., color changes).
- [ ] Reports: Render for empty/non-empty; charts handle zero data.
- [ ] Security: Role checks for overrides; PII encrypted.
- [ ] Tests: Unit for formulas; UI for flows; i18n for locales.
- [ ] Performance: No lag in large lists; offline mode functional.

This updated v1.1 refines structure (e.g., grouped buttons by screen, added architecture notes), fills minor gaps (e.g., command palette, merge in profile), and enhances best practices (e.g., security section). I recommend keeping this as a **new merged SSOT doc** (e.g., name it **EVENTDESKPRO_SSOT.md**) for reference alongside originals during transition—then archive the old ones once validated. If you prefer restructuring into a direct replacement for **SWIFT_APP_LOGIC_PROMPT.md** (e.g., with its Plan → Execute format), let me know for that version!



Here’s the **merged, authoritative doc (v1.1)** you asked for — I’ve folded in all contradictions, missing flows, and best practices. This now functions as a complete SSOT for EventDeskPro logic/flows:

---

# EventDeskPro — Logic & Flow SSOT (v1.1)

**Scope**: This document consolidates and supersedes **UI\_SPEC\_ASCII.md**, **ISSUES\_CHECKLIST.md**, and **SWIFT\_APP\_LOGIC\_PROMPT.md** into a single, authoritative reference for the Swift/iOS/macOS implementation of EventDeskProApp. It resolves contradictions (colors, formulas), fills gaps (VIP tagging, audit trails, etc.), and incorporates best practices (MVVM, security, testing).

Version history tracks changes; this is **v1.1** (added security/privacy section, refined QA, included command palette). Any changes must update this file via approved PRs.

---

## Architecture Notes (Best Practices)

* **MVVM**: Core models (Rust FFI → EDPCore.swift), SwiftUI Views, ViewModels as glue.
* **Data**: Offline-first (SQLite via Rust core). Queue actions for sync.
* **Security & Privacy**: Role-based access (manager overrides), Keychain + SQLite crypto, audit logs, GDPR/CCPA consent for notifications.
* **Performance**: Lazy lists, caching, Instruments profiling.
* **Testing**: Unit (XCTest formulas), UI (XCUITest flows), snapshots. CI/CD with GitHub Actions.
* **Internationalization**: NSLocalizedString, RTL support, locale-aware dates.
* **Extensibility**: Custom statuses map to canonical enums; persisted in settings.

---

## Time Zone Consistency (v1.3)

- Use a single reusable component for all time zone inputs: `TimezonePicker(timezoneId:)`.
- Behavior:
  - Defaults to the system time zone at the top of the list (shown as “System (America/… )”).
  - Presents a curated list of common IANA identifiers (UTC, US regions, London/Berlin, Tokyo/Singapore, Sydney).
  - Binds to a `String` IANA identifier and persists that value in the DB/API.
  - Accessible label provided; supports keyboard selection.
- Applied in:
  - New Event modal (create flow)
  - Event Settings (edit flow)
  - Settings (global default)
- Validation:
  - If the identifier is not recognized by `TimeZone(identifier:)`, a warning appears beneath the picker; saves may still proceed if business rules permit.
  - Includes a built‑in search field to filter the list (falls back to full IANA list when searching; curated list otherwise).
- Rationale:
  - Ensures consistent UX and reduces invalid entries compared to free‑form text fields.


---

## 1. Page Inventory

* Dashboard (Events List)
* Attendees Tab
* Attendee Detail Drawer
* Add Attendee (Search-first)
* Walk-in Registration
* Reports & Analytics
* Settings
* CSV Import/Export
* Global Member Profile
* Error/Loading/Empty States
* Shortcuts Overlay
* Command Palette (⌘⇧P)

---

## 2. Buttons & Actions (Complete)

All actions emit audit logs + refresh views.

**Dashboard**

* \[ + New Event ]
* Row: Open / Edit / Delete
* Auto capacity warning banner

**Attendees Tab**

* \[ + Add Attendee ]
* \[ 👋 Walk-in ]
* \[ Import CSV ] / \[ Export CSV ]
* \[ ✉ Send Emails ]
* Bulk: \[Select All], \[Mark Checked-In], \[Mark DNA], \[Remove]
* Context menu: Check-In, DNA, Confirm, Star, Email, Remove

**Drawer**

* Status toggles (Pre-Reg / Walk-in / Checked-In / DNA)
* \[ Confirm ✔ ] (flag)
* \[ Star ⭐ ] (VIP/speaker/staff)
* \[ Open Member Profile ]
* \[ Remove from Event ]
* \[ Save Changes ]
* Audit timeline panel

**Add Attendee**

* Search existing → \[ Select ]
* New form → \[ Add Attendee ]
* Initial Status (radio, default from settings)
* [x] Send confirmation toggle

**Walk-in**

* Minimal form
* \[ Quick Register ] / \[ Register & Check-In ]

**Reports**

* Chart tabs: Curve, No-show, Funnel
* \[ Export (CSV/PNG) ]

**Settings**

* Color pickers
* Default status dropdown
* DNA timeout (minutes)
* Toggles: auto-confirm, directory sync, custom statuses
* Theme & timezone

**Global Member Profile**

* Edit fields (sync to linked events)
* Merge duplicates
* \[ Close ]

**Cross-cutting**

* Command Palette (⌘⇧P)
* Shortcuts Overlay (?)

---

## 3. Status State Machine

**Canonical**: preRegistered, walkIn, checkedIn, didNotAttend, cancelled
**Rules**:

* Pre-Reg → Confirmed → Checked-In
* Walk-in → Checked-In
* Any → DNA (override if early; auto if timeout)
* Any → Cancelled (excluded from metrics)
* Undo requires reason

**Side Effects**: timestamps, optional notifications, audit logs.

---

## 4. Analytics & Formulas

* **Reg%** = (Pre-Reg + Walk-in + Checked-In) ÷ Capacity
* **No-show Rate** = DNA ÷ (Pre-Reg + Walk-in)
* **Conversion Funnel** = Pre-Reg → Confirmed → Checked-In
* **Check-in Curve** = time-bucketed checkedInAt
* Empty/zero data handled gracefully.

---

## 5. Navigation Flow

Dashboard → Event → Tabs (Attendees/Reports/Settings)
Attendees → Row → Drawer
Drawer → Member Profile
Add/Walk-in/Import = modals
Deep link: `/events/:id?tab=attendees&highlight=attendeeId`
Command Palette → any action
All modals have Cancel/Close (no dead ends).

---

## 6. Error/Empty/Loading

* Empty: “No attendees yet — \[Add Attendee]”
* Loading: spinner
* Error: ⚠️ banner + \[Retry] / \[View Logs]

---

## 7. Accessibility & Shortcuts

* WCAG AA contrast; labels/icons augment colors.
* Keyboard shortcuts: `/` (search), `?` (overlay), `N` (new event), `A` (add), `W` (walk-in), `Esc` (close), `⌘⇧P` (palette).

---

## 8. Contradictions Resolved

* **Colors**: Blue Pre-Reg, Purple Walk-in, Green Checked-In, Gray DNA. (Ignore Amber/Red suggestions).
* **Formulas**: Standardized; Walk-ins included in no-show denominator.
* **Statuses**: Fixed enums + custom mapping.
* **DNA vs Cancelled**: distinct; Cancelled added separately.

---

## 9. QA Checklist

* [ ] All screens/buttons mapped trigger → logic → outcome.
* [ ] Status machine enforced (invalid transitions blocked).
* [ ] Analytics validated with sample data.
* [ ] Colors/contrast checked.
* [ ] Navigation covers all paths (no dead ends).
* [ ] CSV import: preview + error CSV + dedupe.
* [ ] Settings persist + hot-reload.
* [ ] Reports render for empty/non-empty data.
* [ ] Security: role-based overrides; PII encrypted.
* [ ] Tests: unit + UI + i18n.
* [ ] Performance: lists >1k attendees responsive; offline mode works.

---

This is now a **single source of truth** that devs/design/QA can rely on.

---

Do you want me to **save this as `EVENTDESKPRO_SSOT.md`** (a new doc alongside your old ones), or directly **overwrite `SWIFT_APP_LOGIC_PROMPT.md`** so the repo only carries one definitive logic spec?
