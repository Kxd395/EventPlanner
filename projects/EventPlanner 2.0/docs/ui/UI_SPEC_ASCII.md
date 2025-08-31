# UI Spec (ASCII) — v1.1 Aligned to SSOT
Last Updated: 2025-08-29 23:15:47Z

Related docs: [Logic Mapping Prompt](../swift/SWIFT_APP_LOGIC_PROMPT.md) · [Issues Checklist](../issues/ISSUES_CHECKLIST.md) · [Progress](../progress/PROGRESS.md)

## Time & Timezones (SSOT)

- Storage: persist UTC instants + IANA timezone ID (e.g., `America/New_York`).
- Picker: uses `TimeZone.knownTimeZoneIdentifiers` with search; no hardcoded list.
- Validation: disable save if `TimeZone(identifier:) == nil`.
- Display: convert to local for UI; show short TZ (e.g., EDT) alongside times.
- Rust core: accept IANA IDs; convert for display/analytics server-side when needed.

## Status Chips (Attendees Tab)

```
Pre-Registered (Blue) | Walk-in (Purple) | Checked-In (Green) | DNA (Gray)
[■ Pre-Registered 128] [□ Walk-in 12] [□ Checked-In 84] [□ DNA 6]
Search: [ jane ]   Sort: (●) Name  ( ) Status  ( ) Check-in Time
```

- Active chip = solid; inactive = outlined.
- Clicking filters list; clicking active clears.

---

## Attendees Header Actions

```
[ + Add Attendee ]  [ 👋 Walk-in ]  [ Import CSV ] [ Export CSV ] [ ✉ Send Emails ]
Selection: [ n selected ]   [ Mark Checked-In ]  [ Mark DNA ]  [ Remove ]
```

---

## Attendee Row → Right Drawer Panel

```
+----------------- Attendee — Jane Lee (Orbit Labs) ------------------+
| Contact (Global)            | Participation (Event-specific)        |
| Name: Jane Lee              | Status: [Pre-Reg] [Walk-in] [✓Check] [DNA] |
| Email: jane@orbit.io        | Ticket:  VIP ⭐   Seat: A-12          |
| Phone: +1 555-111-2222      | Check-in Time: 2025-09-03 09:12       |
| Company: Orbit Labs         | Source: prereg                        |
| Tags: [speaker] [+]         | Event Notes: [ ... ]                  |
|                             | Bulk: [ Mark Checked-In ] [ Mark DNA ]|
+---------------------------------------------------------------------+
|  [ Confirm ✔ ]  [ Star ⭐ ]  [ Open Member Profile ]                 |
|  [ Remove from Event ]  [ Save Changes ]                            |
+---------------------------------------------------------------------+
| Audit Timeline:                                                  |
| • 09:12 Checked-In by staff01                                     |
| • 09:15 DNA override by manager02 (reason: left early)            |
+---------------------------------------------------------------------+
```

---

## Add Attendee (Revised Workflow)

```
+--------------------------- Add Attendee ----------------------------+
| Search Existing Members:                                            |
| [ email, name, or phone…             ] [🔍 Search] [Clear]          |
|                                                                       |
| Results (live typing):                                                |
| • Jane Lee (Orbit Labs) — 3 events [ Select ]                        |
| • Jane Doe (TestCorp) — 1 event [ Select ]                           |
|                                                                       |
| ⚠ Possible match: "Lee" already exists in member database            |
|    Suggestion: Jane Lee (Orbit Labs, 3 events) [ Open Profile ]       |
+---------------------------------------------------------------------+
| Or Create New Member:                                                |
| First Name *  [ Jane ]          Last Name *   [ Lee ]                |
| Email *       [ jane@orbit.io ] Phone         [ +1 555-222-0199 ]    |
| Company       [ Orbit Labs ]    Tags          [ + Add Tag ]          |
|                                                                       |
| Membership: [x] Add to Global Member Database                        |
|             [ ] Event-only (ad-hoc attendee, not saved globally)     |
|                                                                       |
| Initial Status: (●) Pre-Registered  ( ) Walk-in  ( ) Checked-In      |
| Options: [x] Send confirmation   [ ] VIP ⭐                          |
|                                                                       |
| Actions: [ Cancel ]        [ Add Attendee ]                          |
+---------------------------------------------------------------------+
```

What’s New
- Member checkbox: Default ON. Creates/links a global member unless unchecked.
- Event-only mode: When OFF, add as transient attendee only (no global record).
- Live duplicate detection: Fuzzy on last name; inline warning + suggestions.
- Open profile: Clicking suggested match opens existing Member Profile.
- Inline membership info: Existing = “Global Member (n events)”; new = checkbox to promote.
- VIP toggle + tags: Capture role/flags during creation.

SSOT Delta — Add Attendee
- Search-first supports live fuzzy matching (email, phone, last name).
- Duplicate detection shows suggestions before pressing Search.
- Membership checkbox defaults to ON (Add to Global Members).
- Allow event-only transient attendees if unchecked.
- Warning banner: “Possible match” when last name/email overlap.

---

## Walk-in Registration (Minimal)

```
+------------------------- Walk-in Registration -----------------------+
| Name * [ Full Name ]  Email [ optional ]  Company [ ]  Phone [ ]     |
| Status: (●) Walk-in  ( ) Checked-In  [✓] Immediate check-in          |
| Actions: [ Cancel ]  [ Quick Register ] [ Register & Check-In ]      |
+---------------------------------------------------------------------+
```

---

## Confirmations & Safeguards

```
Mark as Checked-In?                     | Undo Check-In (Reason Required)
[ Cancel ] [ ✓ Confirm Check-In ]       | Reason * [__________] [ Cancel ] [ Confirm ]

Early DNA (Event in progress)           | Bulk Early DNA (Manager Override)
⚠ Requires manager override             | Confirm override for 12 attendees?
[ Cancel ] [ Override & Mark DNA ]      | [ Cancel ] [ Confirm Override ]
```

---

## CSV Import Preview

```
+------------------------ Import Preview -----------------------+
| File: attendees.csv     Total: 120  Valid: 112  Duplicates: 6 |
| Errors: 2  [ Download Errors CSV ]                            |
| Duplicates (link to global): jane@x.io, sam@y.co, …           |
| [ Cancel ]                                      [ Commit ]    |
+---------------------------------------------------------------+
```

---

## Reports & Charts

```
Event Summary
Pre-Reg |██████████      | 128
Walk-in |█████           |  42
Checked |███████████████ | 210
DNA     |██              |  18

Check-in Curve
[■■■□□□□■■■□□□□■■■■■■■□□□□]

No-show Rate (DNA ÷ (Pre-Reg+Walk-in))
[■■■■■□□□□]

Conversion Funnel
Pre-Reg → Confirmed → Checked-In
128 → 100 → 84
```

---

## Settings

```
+--------------------------- Settings ----------------------------+
| Organization: [___________]                                     |
| Theme: (●) Light  ( ) Dark                                      |
| Timezone: [ America/New_York ▼ ]                               |
|                                                                 |
| Status Colors: Pre-Reg [Blue]  Walk-in [Purple]                 |
|                Checked-In [Green]  DNA [Gray]                   |
|                                                                 |
| Default Initial Status: (●) Pre-Reg  ( ) Walk-in                |
| DNA Auto-timeout (min): [  60 ]                                 |
|                                                                 |
| Toggles: [x] Auto-send Confirmations                            |
|          [x] Sync Directory                                     |
|          [ ] Enable Custom Statuses                             |
+----------------------------------------------------------------+
```

---

## Keyboard Shortcuts & Command Palette

```
+------------------------- Shortcuts -----------------------------+
| Global:  /  Focus Search   |  ?  Show Shortcuts                |
| Events:  N  New Event      |                                  |
| Attnds:  A  Add Attendee   |  W  Walk-in   |  Esc  Close Panel|
| Palette: ⌘⇧P  Command Palette (search all actions)            |
+----------------------------------------------------------------+
```

---

## Empty / Loading / Error States

```
Attendees (Empty)
📋 No attendees yet — Add your first attendee [Add Attendee]

Loading
⏳ Loading attendees…

Error
⚠️  Couldn’t load attendees. [ Retry ]   [ View Logs ]
```

---

## Deep-Link & Highlight

```
Route: /events/57?tab=attendees&highlight=att_abc123
- On mount, scroll to row ID and apply highlight ring within 500ms.
- “Back” restores prior tab + scroll.
```

---

## Accessibility

- Buttons: accessible names (e.g., “Mark Checked-In”).
- Contrast ≥ 4.5:1; color not sole indicator.
- Focus order logical; no traps.
