# EventDeskPro — UI/UX Audit & Updated TODO (v1.2)

## 1) Executive Summary
EventDeskPro’s macOS app is broadly aligned with the v1.0/v1.1 designs: the Attendees view supports Table | Cards modes, cards include presence dots, compact actions and status chips, and the Public Registration flow is present with signed links and a QR modal. The app now includes text‑only filter behavior in code, Undo/Reset scaffolding, and an API Base integration for pulling public registrations.

Gaps remain where older behaviors linger or where v1.1 features are only partially implemented. Most are additive and low‑risk: replace the colored/count filter chips with the text‑only filter bar everywhere, formalize the pinned footer scaffold, unify Import/Export menus, and complete Undo/Reset UX (row ⋯ menu, bulk options, and a future timeline revert). These changes improve clarity, reduce duplicated controls, and make actions auditable and reversible.

---

## 2) Global Fixes (Cross‑Screens)
- [ ] Pinned footer layout: one scroll surface; footer via `safeAreaInset(edge: .bottom)`; remove nested ScrollViews and stray `Spacer()` that cause drift.
  - Files: propose new `apps/EventDeskProApp/Sources/Views/Common/AppScaffold.swift`
  - Accept: Footer remains glued when resizing; content stretches to fill.
- [ ] AppScaffold adoption: convert top‑level views to header → content → footer scaffold.
  - Files: `apps/EventDeskProApp/Sources/Views/ContentView.swift`, entry screens.
  - Accept: No duplicate scroll areas; consistent padding and dividers.
- [ ] Unified Import/Export menus across Events, Attendees, Members.
  - Formats: CSV, JSON, Markdown (.md), TXT; Scope: All / Filtered / Selected; PII toggles by role.
  - Files: add `apps/EventDeskProApp/Sources/Views/Menus/ExportMenu.swift`, `.../Menus/ImportMenu.swift`; integrate in: `EventsListView.swift`, `AttendeesView.swift`, `MembersListView.swift`.
  - Accept: Same menu everywhere; file naming `context_YYYY‑MM‑DD_entity.ext`.
- [ ] Keyboard & a11y polish: `/` search focus, `?` shortcuts overlay, `⌘⇧P` command palette, `1…5` filter tabs; Esc closes modals; VoiceOver labels on chips/buttons.
  - Files: app‑wide Commands in `ContentView.swift`; add a lightweight Shortcuts overlay view.
  - Accept: Shortcuts listed; VoiceOver reads labels and selected states.

---

## 3) Events List (Table & Cards)
- [ ] View mode toggle Table | Cards (`@AppStorage("events.viewMode")`).
  - Files: `apps/EventDeskProApp/Sources/Views/Events/EventsListView.swift`
  - Accept: Toggle persists; reopening app restores mode.
- [ ] Responsive density & spacing; footer pinned; empty state copy.
  - Files: `EventsListView.swift`; adopt `AppScaffold`.
  - Accept: No drift; empty copy appears when no events.
- [ ] Bulk actions parity: selection bar with Export/Remove actions consistent with Members/Attendees.
  - Files: `EventsListView.swift`.
  - Accept: Selection bar shows counts and actions; disabled when invalid.

---

## 4) Event Detail — Attendees Tab
- [ ] Filters: replace colored/count chips with text‑only filter bar; keep Summary metric cards read‑only, non‑interactive.
  - Files: `apps/EventDeskProApp/Sources/Views/Components/StatusChip.swift`, `.../Attendees/AttendeesView.swift`
  - Accept: Buttons show only text; counts move to cards/Total label.
- [ ] Cards grid: two‑column responsive cards; presence dot, name, company/email, status chips, actions (Check‑In, Email, Remove), kebab (⋯) menu.
  - Files: `.../Attendees/AttendeeCard.swift` (updated), `.../Attendees/AttendeeRow.swift` (list)
  - Accept: Grid adapts; ⋯ shows Undo/Reset/Remove.
- [ ] Undo/Reset:
  - [ ] After any status change, show Undo toast (30s) + `⌘Z`.
  - [ ] Kebab Reset Participation… (row + bulk): Revert to previous (pending history), Set Pre‑Registered, Mark Cancelled, Remove (guards honored).
  - Files: `AttendeesView.swift` (toast + undo already present), `ResetParticipationSheet.swift` (added), Status guards in `StatusChangeSheet.swift`.
  - Accept: Undo reverses latest change; Reset → Pre‑Registered clears timestamps; Remove unlinks; reason required when guard demands it.
- [ ] Change Status modal: Confirm disabled for no‑op; on confirm → VM/FFI → refresh counts → toast; guard DNA during event unless override.
  - Files: `StatusChangeSheet.swift` (updated), `AttendeesView.swift` (applyStatus/bulk path)
  - Accept: Confirm disabled if selecting current; reason needed per rules.
- [ ] Capacity line & counts visible and live.
  - Files: `AttendeesView.swift` (`CapacityHeaderView`)
  - Accept: Counts change immediately after updates.

---

## 5) Add Attendee Modal (Search‑First)
- [ ] Live duplicate hint on last name/email/phone; prevent accidental dupes; “Open Profile” from suggestion.
  - Files: `apps/EventDeskProApp/Sources/Views/Attendees/AddAttendeeSheet.swift`
  - Accept: Typing shows possible match; selecting fills; duplicates avoided.
- [ ] Initial status radio; Add to Global Member Database (default ON); VIP toggle; Send confirmation checkbox; email/phone validation.
  - Files: `AddAttendeeSheet.swift`
  - Accept: Fields validate; dedupe by email/phone works; success banner.

---

## 6) Members (Global)
- [ ] View mode toggle Table | Cards; card shows tags/company/email; actions (Email, Add to Event, Remove).
  - Files: `apps/EventDeskProApp/Sources/Views/Members/MembersListView.swift`
  - Accept: Toggle persists; selection bar parity.
- [ ] Add Member modal mirrors Add Attendee; dedupe, Merge Duplicates flow, consistent banners.
  - Files: `.../Members/AddMemberSheet.swift`, `.../Members/MergeDuplicatesSheet.swift`
  - Accept: Same UX as Attendee creation; merge success path verified.

---

## 7) Member Profile Modal
- [ ] Save & Close primary + ×; global contact fields; participation chips (this event) with guarded transitions; timeline/audit with “Revert to this point…”.
  - Files: `apps/EventDeskProApp/Sources/Views/Members/MemberProfileView.swift`
  - Accept: Profile edits save; per‑event chips mutate status with guards; timeline visible (stub until FFI ready), Revert stubbed.

---

## 8) Settings — Event Basics & Timezone
- [ ] Timezone Picker: searchable IANA list; default System; no hardcoded strings.
  - Files: `apps/EventDeskProApp/Sources/Views/Components/TimezonePicker.swift`
  - Accept: Typing filters identifiers; invalid TZ rejected.
- [ ] Location field styling fix; Description grows; Save button disabled until changes.
  - Files: `apps/EventDeskProApp/Sources/Views/EventSettingsView.swift`
  - Accept: Baseline alignment; Save enabled only on diff.
- [ ] Public Registration control visible per event.
  - Files: `apps/EventDeskProApp/Sources/Views/EventDetailView.swift`
  - Accept: Button opens modal; QR/Link present.

---

## 9) Public Registration / QR
- [ ] Event header “Public Registration” button opens modal with Enable toggle, signed URL, QR code and actions (Copy Link/Save PNG/Regenerate).
  - Files: `EventDetailView.swift`, `.../Components/PublicRegistrationQRView.swift`
  - Accept: Secret stored in Keychain by event; URL regenerates with TTL.
- [ ] Optional email verification toggle.
  - Files: extend modal state in `EventDetailView.swift`
  - Accept: Toggle persists (stub if backend not ready).
- [ ] On submit, pre‑register via backend; poll `GET /api/events/:id/registrations?since=` or use SSE; offline‑first fallback.
  - Files: `RegistrationSyncService.swift`; sample in `samples/backend/axum_register.rs`
  - Accept: New registrations appear as Pre‑Registered automatically.

---

## 10) QA Checklist (Copy‑Ready)
- [ ] Only one interactive filter control on Attendees (text‑only bar); summary cards read‑only; hide on narrow (<640pt).
- [ ] Change Status modal writes through to core; Undo works; counts refresh.
- [ ] Timezone search returns valid IANA ids; persists.
- [ ] Unified Export/Import menus present and consistent; filenames follow `context_YYYY‑MM‑DD_entity.ext`.
- [ ] Empty/Loading/Error states show; banners accessible; Esc closes dialogs.

---

## 11) Implementation Notes (Code Pointers)

- FilterBar (text‑only)
```swift
struct FilterBar: View {
    @Binding var selected: StatusFilterBar.Status
    var total: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(StatusFilterBar.Status.allCases, id: \.rawValue) { s in
                let isSel = (s == selected)
                Button(s.title) { selected = s }
                    .buttonStyle(.plain)
                    .padding(.vertical, 6).padding(.horizontal, 12)
                    .background(isSel ? s.color : .clear)
                    .foregroundColor(isSel ? .white : s.color)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(s.color, lineWidth: isSel ? 0 : 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Spacer()
            Text("Total: \(total)").foregroundStyle(.secondary)
        }
    }
}
```

- UndoToast + ⌘Z
```swift
.safeAreaInset(edge: .bottom) {
    if let toast = toast { ToastView(text: toast, actionTitle: "Undo", action: { undoLastChange() }) }
}
.commands {
    CommandGroup(after: .undoRedo) {
        Button("Undo Status Change") { undoLastChange() }.keyboardShortcut("z", modifiers: [.command])
    }
}
```

- changeStatus VM method (persist → refresh → toast)
```swift
func applyStatus(ids: [String], newStatus: String, reason: String?, override: Bool) {
    let prior: [String:String] = attendees.reduce(into: [:]) { if ids.contains($1.attendeeId) { $0[$1.attendeeId] = $1.status } }
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let n = try EDPCore.shared.bulkStatusUpdate(eventId: event.id, attendeeIds: ids, newStatus: newStatus, inProgress: isEventInProgress(event: event), override: override, reason: reason, changedBy: "ui")
            DispatchQueue.main.async { load(); lastStatusChange = (ids, prior, newStatus); toast = "Updated \(n)" }
        } catch { DispatchQueue.main.async { error = EDPCore.shared.lastError() ?? "Update failed" } }
    }
}
```

- TimezonePicker (IANA search)
```swift
let zones = TimeZone.knownTimeZoneIdentifiers
TextField("Search timezones", text: $query)
List(zones.filter { query.isEmpty ? true : $0.localizedCaseInsensitiveContains(query) }, id: \.self) { id in Text(id) }
```

- AppScaffold (single scroll + pinned footer)
```swift
struct AppScaffold<H: View, C: View, F: View>: View {
  @ViewBuilder var header: () -> H; @ViewBuilder var content: () -> C; @ViewBuilder var footer: () -> F
  var body: some View {
    VStack(spacing: 0) { header(); Divider(); content().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) }
    .safeAreaInset(edge: .bottom) { VStack(spacing: 0) { Divider(); footer().font(.footnote).padding(.vertical, 6).padding(.horizontal, 10) }.background(.regularMaterial) }
  }
}
```

- ExportMenu (formats & scope)
```swift
struct ExportMenu: View { let onExport: (Format, Scope) -> Void
    enum Format { case csv, json, md, txt }; enum Scope { case all, filtered, selected }
    var body: some View {
        Menu {
            Menu("CSV") { Button("Filtered") { onExport(.csv, .filtered) }; Button("Selected") { onExport(.csv, .selected) }; Button("All") { onExport(.csv, .all) } }
            Menu("JSON") { Button("Filtered") { onExport(.json, .filtered) }; Button("Selected") { onExport(.json, .selected) }; Button("All") { onExport(.json, .all) } }
            Button("Markdown (.md)") { onExport(.md, .filtered) }
            Button("Plain Text (.txt)") { onExport(.txt, .filtered) }
        } label: { Label("Export", systemImage: "tray.and.arrow.up") }
    }
}
```

Files to touch
- `apps/EventDeskProApp/Sources/Views/Attendees/AttendeesView.swift`
- `apps/EventDeskProApp/Sources/Views/Attendees/StatusChangeSheet.swift`
- `apps/EventDeskProApp/Sources/Views/Attendees/AttendeeRow.swift`
- `apps/EventDeskProApp/Sources/Views/Attendees/AttendeeCard.swift`
- `apps/EventDeskProApp/Sources/Views/Attendees/ResetParticipationSheet.swift`
- `apps/EventDeskProApp/Sources/Views/Components/StatusChip.swift`
- `apps/EventDeskProApp/Sources/Views/Events/EventsListView.swift`
- `apps/EventDeskProApp/Sources/Views/Members/MembersListView.swift`
- `apps/EventDeskProApp/Sources/Views/Members/MemberProfileView.swift`
- `apps/EventDeskProApp/Sources/Views/EventSettingsView.swift`
- `apps/EventDeskProApp/Sources/Views/EventDetailView.swift`
- New: `apps/EventDeskProApp/Sources/Views/Common/AppScaffold.swift`, `.../Views/Menus/ExportMenu.swift`

---

## 12) Prioritization & Risk
- P0 (Now)
  - [ ] Text‑only Filter Bar everywhere; remove count chips from filters.
  - [ ] Undo toast + `⌘Z` polished (already present, verify timing/stack).
  - [ ] StatusChangeSheet no‑op guard (done) and DNA guard messaging.
  - [ ] Reset ⋯ menu (done) + Pre‑Registered and Remove paths verified.
  - Risk: Low; contained to SwiftUI; uses existing FFI.
- P1 (Next)
  - [ ] AppScaffold + pinned footer adoption across screens.
  - [ ] Unified Export/Import Menus; file naming and PII gating.
  - [ ] Members/Events parity (cards/table, bulk selection bars).
  - Risk: Medium; touches multiple views; ensure no nested scrolls.
- P2 (Nice)
  - [ ] Participation history (FFI) and “Revert to this point…” timeline.
  - [ ] Public Registration: email verification toggle; SSE client to replace polling.
  - Risk: Medium–High for FFI; requires backend/core changes.

If any spec conflicts with current code, prefer the v1.1 Logic and ASCII v1.1 patterns: single interactive filter bar, read‑only summary cards, pinned footer, and auditable Undo/Reset.
