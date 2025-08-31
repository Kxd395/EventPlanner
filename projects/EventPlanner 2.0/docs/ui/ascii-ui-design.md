EventDeskPro ASCII UI Design Sheet (v3.1)

Created: 2025-08-20 13:00 EST
Last Updated: 2025-08-29 23:59 UTC
Author: UI/UX Design Team
Version: 3.1.0 — Enhanced Attendee Workflow (SSOT-Aligned)
Status: SSOT — System Logic Source of Truth
Platforms: React Web · Swift macOS

⸻

0) Global Conventions
	•	Capacity wording: “Max guests (capacity)”. Helper: “Use 0 for unlimited. Whole numbers only.”
	•	Time zone: IANA Picker everywhere (store ID like America/New_York; display local with short TZ).
	•	Unified menus: Import/Export dropdowns on Events, Members, Attendees (optional Reports).
	•	Import: CSV / JSON / TXT
	•	Export: CSV / JSON / Markdown (.md) / TXT
	•	Scope (export): Filtered (default) / All / Selected
	•	Filenames: context_YYYY-MM-DD_entity.ext
	•	PII gating: If role lacks permission, disable CSV/JSON; MD/TXT redact email/phone/notes.
	•	Status vocabulary (canonical): Pre-Registered, Walk-in, Checked-In, Did Not Attend (DNA).
	•	Row badges: ⭐ VIP · 🏷 Member · ⚡ Walk-in · ☑︎ Confirmed (plus status color dot).

⸻

1) Global App Frame (Desktop)

```
+------------------------------------------------------------------------------------------------+
| ☰ Logo/Name     [ Search… ]                                              🔔  ⟳ Sync  User ▼  🌓 |
+------------------------------------------------------------------------------------------------+
| Dashboard | Events | Members | Reports | Settings | Help                                          |
| Breadcrumb: Home / Dashboard                                           Date: 2025-08-28          |
+------------------------------------------------------------------------------------------------+
| Status Summary (4-up)                                                                      ▲     |
| +----------------+ +----------------+ +----------------+ +----------------+                       |
| | Total Events   | | Active Events  | | Attendees      | | This Week      |                       |
| |        42      | |        18      | |        865     | |        7       |                       |
| +----------------+ +----------------+ +----------------+ +----------------+                       |
| Upcoming Events (Next 5)                                                    [ + New Event ]       |
| • Dev Summit 2025   | 2025-09-03 | 240 / 400 | Active   | Manage ▸                              |
| • Product Launch    | 2025-09-09 | 120 / 250 | Draft    | Manage ▸                              |
| Recent Members: Jane Lee · Carlos Santos · Mia Park                                           |
| Quick Actions: [ + Event ] [ + Member ] [ Export ▼ ] [ Reports ] [ Settings ]                    |
| Footer: © 2025 EventDeskPro · v1.0.0 · Keyboard: ? · API: OK (120ms)                             |
+------------------------------------------------------------------------------------------------+
```

⸻

2) Events List (Bulk & Menus)

```
Events   [ Search events… ]  [ Status ▼ ]  [ Export ▼ ]  [ Import ▼ ]                    (+)
+----------------------+--------------+-----------+-----------+-----------+-----------+---------+
| ☐ (All)              | Name         | Date/TZ   | Status    | Capacity  | Reg (%)   | Actions |
+----------------------+--------------+-----------+-----------+-----------+-----------+---------+
| ☐                    | Dev Summit   | 2025-09-03| Active    | 400       | 60%       | ✏ 👁 ⧉ 🗑 |
| ☐                    | Workshop 1   | 2025-09-14| Active    | 60        | 53%       | ✏ 👁 ⧉ 🗑 |
+------------------------------------------------------------------------------------------------+
Bulk: [ Delete ] [ Duplicate ] [ Export ▼ ] [ Mark Active ] [ Mark Draft ]
Empty: 📂 No events yet — Create your first event [ Create Event ]

New Event (Modal)

Event name *               [ ______________________________ ]
Start / End *              [ 2025-09-03 09:00 ] – [ 17:00 ]
Time zone *                [ America/New_York ▼ ]   (Picker)
Location / Venue           [ ______________________________ ]
Max guests (capacity)      [ 0 ]   (Use 0 for unlimited. Whole numbers only.)
Description                [ Internal notes…                            ]
Actions: [ Cancel ]                                         [ Create ]
```

⸻

3) Members List (Global Database)

```
Members   [ Search members… ]  [ Company ▼ ]  [ Export ▼ ]  [ Import ▼ ]                  (+)
+----------------------+------------------+----------------------+--------------+-----------+
| ☐ (All)              | Name             | Email                | Company      | Events    |
+----------------------+------------------+----------------------+--------------+-----------+
| ☐                    | Jane Lee         | jane@orbit.io        | Orbit Labs   | 3 events  |
| ☐                    | Carlos Santos    | carlos@intra.io      | IntraCloud   | 1 event   |
+------------------------------------------------------------------------------------------+
Bulk: [ Email ] [ Add to Event ] [ Export ▼ ] [ Delete ] [ Merge Duplicates ]
Note: Members = global persons across all events.
```

⸻

4) Event Detail (Tabbed)

```
← Back to Events   Dev Summit 2025           [ Edit ] [ Duplicate ] [ ⋮ ]
Status: ACTIVE • 2025-09-03 09:00–17:00 • Convention Center (Hall A)
Tabs: Overview | Attendees | Schedule | Assets | Settings | Reports

Overview

Metrics: Registrations 240 • Capacity 400 (60%) • Checked-In 0
Description: “Annual developer summit on distributed systems…”
Notes/Tasks panels as needed.
```

⸻

5) Attendees Tab (Enhanced)

Header

```
[ + Add Attendee ]  [ 👋 Walk-in ]  [ Import ▼ ]  [ Export ▼ ]  [ ✉ Send Emails ]   Search [ ]
Selection: [ n selected ]   [ Mark Checked-In ]  [ Mark DNA ]  [ Remove ]
```

Capacity Header

```
Capacity: 42 / 150 guests   (28% filled)   [ Progress ▓▓░░░ ]
– If capacity = 0 → “Unlimited guests” (no bar) –
```

Status Chips

```
[■ Pre-Registered 128] [□ Walk-in 12] [□ Checked-In 84] [□ DNA 6]
Sort: (●) Name  ( ) Status  ( ) Check-in Time
```

List Row

```
●  kevin dial   dil@myyhoo.com
   Badges: ⭐  🏷  ⚡  ☑︎        Status: Pre-Registered
   (Row menu: Check-In • Mark DNA • Confirm • ⭐ Star • Email • Remove)
```

Attendee Detail — Card/Form Drawer

```
+------------------------- Attendee — kevin dial --------------------------+

Contact (Global)
  Name: [ kevin dial ]    Email: [ dil@myyhoo.com ]   Phone: [ ________ ]
  Company: [ _________ ]  Tags: [ vip, speaker ][ + ]
  Member: [x]     VIP ⭐: [x]

Participation (Event-specific)
  Status: [ Pre-Registered ] [ Walk-in ] [ Checked-In ] [ DNA ] [ Cancelled ]
  Confirmed: [x]    Walk-in flag: [x]
  Check-in time: [ 2025-09-03 09:12 ]   [ Set Now ] [ Clear ]
  No-show (DNA): [ — ]                  [ Set Now ] [ Clear ]
  Auto-DNA timer (min): [ 60 ]   (0 = off; blank = inherit event default)
  Notes: [ … event-specific notes … ]

Actions: [ Remove from Event ]                                  [ Save Changes ]
Audit Timeline:
  • 09:12 Checked-In by staff01
  • 09:15 DNA override by manager02 (reason: left early)
+---------------------------------------------------------------------------+
```

⸻

6) Add Attendee (Revised Workflow)

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
- Member checkbox: Default ON → attendee becomes a global member unless unchecked.
- Event-only mode: OFF = transient attendee only (no global record).
- Live duplicate detection: Fuzzy on last name; inline warning + suggestions.
- Open profile from suggestion to avoid creating duplicates.
- Inline membership info: Existing shows “Global Member (n events)”.
- VIP toggle + tags in modal.

SSOT Delta (Add Attendee)
- Search-first supports live fuzzy matching (email, phone, last name).
- Inline duplicate suggestions shown before pressing Search.
- Membership checkbox defaults to ON (Add to Global Members).
- Allow event-only transient attendees when unchecked.
- Show “Possible match” banner when last name/email overlap.

⸻

7) Walk-in Registration (Minimal)

```
+------------------------ Walk-in Registration ------------------------+
Name *  [ Full Name ]    Email [ optional ]   Company [ ]   Phone [ ]
Status: (●) Walk-in  ( ) Checked-In   [✓] Immediate check-in
Auto-link: if email matches Member → link automatically
Actions: [ Cancel ]   [ Quick Register ]   [ Register & Check-In ]
+--------------------------------------------------------------------+
```

⸻

8) Confirmations & Safeguards

```
Mark as Checked-In?               | Undo Check-In (Reason Required)
[ Cancel ] [ ✓ Confirm ]          | Reason * [ __________________ ] [ Cancel ] [ Confirm ]

Mark as Did Not Attend? (event active)      | Bulk DNA (Manager Override)
⚠ Requires manager override                  | Mark 12 attendees as DNA before event end?
[ Cancel ] [ Override & Mark DNA ]           | [ Cancel ] [ Confirm Override ]
```

⸻

9) Import / Export Flows (Unified)

Export dialog (attendees/events/members):

```
Format: (●) CSV  ( ) JSON  ( ) Markdown (.md)  ( ) TXT
Scope:  (●) Filtered  ( ) All  ( ) Selected
PII (role-gated): [x] Email [x] Phone [ ] Notes
[ Cancel ]                          [ Export ]
```

Import dialog (attendees/members):

```
File: [ Choose… ]  or  Drop file here
Preview: shows first 3 rows with inline errors/dupes
Options: [x] Send welcome emails  [ ] Skip duplicates
Status: ✓ 25 valid, ⚠ 2 duplicates, 1 error  [ Download Errors CSV ]
[ Cancel ]                           [ Import ]
```

⸻

10) Reports & Charts

Event Summary (bars)
Check-in Curve (time buckets)
No-show Rate = DNA ÷ (Pre-Registered + Walk-in)
Conversion Funnel: Pre-Registered → Confirmed → Checked-In
Exports per tab: CSV (data) / PNG (chart)

⸻

11) Settings

```
Organization [ ______ ]     Theme: ( ) Light (●) Dark ( ) Auto
Default Time zone: [ America/New_York ▼ ]  (Picker)
Status Colors: Pre-Reg [Blue]  Walk-in [Purple]  Checked-In [Green]  DNA [Gray]
Default Initial Status: (●) Pre-Registered  ( ) Walk-in
Event default — Auto-DNA timeout (min): [ 60 ]  (0 = off)
Data & Export: [ Export All Data ] [ Import Data ] [ Download Error Logs ]
```

⸻

12) Keyboard Shortcuts & Command Palette

Global:  / Focus Search   ? Shortcuts overlay   ⌘⇧P Command Palette
Events:  N New Event
Event:   A Add Attendee   W Walk-in   ⌘S Save   Esc Close Drawer/Modal

⸻

13) Empty / Loading / Error

Attendees (Empty)
📋 No guests registered yet — Add your first guest
[ + Add Guest ]  or  [ Import ]

Loading: ⏳ Loading…
Error:   ⚠ Couldn’t load.  [ Retry ]  [ View Logs ]

⸻

14) Terminology & Codes (Authoritative)
	•	UI terms: Pre-Registered, Walk-in, Checked-In, Did Not Attend (DNA)
	•	DB codes: preregistered, walkin, checkedin, dna
	•	Legacy migrations: registered→preregistered, noshow→dna

⸻

15) Status Machine & Auto-DNA (Summary)
	•	Allowed: Pre-Registered ↔ Checked-In ↔ DNA; Walk-in ↔ Checked-In ↔ DNA
	•	Undo Check-In requires reason (audit). Early DNA blocked unless manager override.
	•	Auto-DNA: At End + N minutes (event default, per-attendee override possible); set dnaAt and create audit entry.

⸻

16) Validation Matrix (UI)

Field                      Required  Rules
Event name                 Yes       3–120 chars
Start/End + Time zone      Yes       End > Start; valid IANA TZ (Picker)
Max guests (capacity)      Yes       Integer ≥ 0 (0 = unlimited)
Email (member)             Usually   RFC basic; unique for member; dedupe on import
Status (attendee)          Yes       Enum (preregistered|walkin|checkedin|dna|cancelled)

⸻

17) Data Flow (High-Level)

[ UI ] → actions → [ ViewModels ] → [ Core API/FFI ] → [ DB ]
          ↑                                      ↓
      optimistic UI ←────────── state sync / audit ──────────

⸻

18) Mobile (Reference)
	•	Collapsed nav, event cards, essential actions only (Add/Walk-in/Status buttons).
	•	Same vocabulary, colors, and confirmation patterns.

⸻

19) QA Acceptance (Spot-check)
	•	Capacity header visible and correct (0 → Unlimited).
	•	Import/Export menus present on Events/Members/Attendees; scope default = Filtered.
	•	PII export rules enforced by role.
	•	Status chips update counts live; badges render.
	•	Drawer shows Contact and Participation cards; ⌘S saves.
	•	Auto-DNA triggers at End + default minutes; per-attendee override wins.
	•	Deep-link highlight works; keyboard shortcuts work.

⸻

This v3.1 sheet is the authoritative UI reference for design, engineering, and QA.
+--------------------------- Add Attendee ----------------------------+
| Search Existing Members:                                            |
| [ jane@orbit.io or name or phone...        ] [🔍 Search] [Clear]    |
|                                                                     |
| Results: ✓ Jane Lee (jane@orbit.io) - Orbit Labs - 3 events        |
| [ Select Member ] → Creates attendee with Pre-Registered status     |
+---------------------------------------------------------------------+
| Or Create New Member:                                               |
| First Name *  [ Jane ]          Last Name *   [ Lee ]               |
| Email *       [ jane@orbit.io ] Phone         [ +1 555 222 0199 ]   |
| Company       [ Orbit Labs ]    Tags          [ + Add Tag ]         |
|                                                                     |
| Initial Status: (●) Pre-Registered  ( ) Walk-in  ( ) Checked-In    |
| Options: [x] Send confirmation   [ ] Manager Override               |
| Safeguards: "Email already exists" (prevents duplicates)           |
| Actions: [ Cancel ]        [ Add Attendee ]                        |
+---------------------------------------------------------------------+
```

## 5A. Walk-in Registration Interface (Minimal Friction)

```
+-------------------------- Walk-in Registration -------------------------+
| Quick Add (Event Day):                                                |
| Name *     [ Full Name                    ] (required)                |
| Email      [ email@domain.com            ] (optional but encouraged) |
| Phone      [ +1 555-xxx-xxxx             ] (optional)                |
| Company    [ Company Name                ] (optional)                |
|                                                                       |
| Auto-link: If email matches existing Member → link automatically     |
| Status: (●) Walk-in  ( ) Checked-In  (toggle for immediate check-in) |
|                                                                       |
| Actions: [ Cancel ]  [ Quick Register ] [ Register & Check-In ]      |
+-----------------------------------------------------------------------+
| Global Database Search (if time permits):                            |
| [ Enter email or name...        ] [Search]                           |
| Found: ✓ Jane Lee (jane@orbit.io) - Previously at 3 events           |
| [ Use Existing Info ] or [ Register as New ]                         |
+-----------------------------------------------------------------------+
```

## 5B. Status Change Confirmations & Safeguards

```
+--------------------------- Confirmation Dialogs ----------------------------+
| Mark as Checked-In?                                                       |
| Jane Lee will be marked as present at Dev Summit 2025.                   |
| [ Cancel ]                    [ ✓ Confirm Check-In ]                     |
+--------------------------------------------------------------------------+
| Undo Check-In (Audit Required)                                          |
| This will revert Jane Lee's attendance. Please provide a reason:        |
| Reason * [ Left early due to emergency                         ]        |
| [ Cancel ]                    [ Confirm Undo ]                          |
+--------------------------------------------------------------------------+
| Mark as Did Not Attend?                                                 |
| ⚠️  Event is still in progress (ends at 17:00)                         |
| Jane Lee will be marked as Did Not Attend. You can undo this later.    |
| [ Cancel ]                    [ Mark DNA ]                              |
+--------------------------------------------------------------------------+
| Bulk DNA (Manager Override)                                             |
| You're marking 12 attendees as Did Not Attend before event end.        |
| This requires manager override. Continue?                               |
| [ Cancel ]                    [ Override & Mark DNA ]                   |
+--------------------------------------------------------------------------+
```

## 5A. Walk-in Registration Interface
```
+-------------------------- Walk-in Registration -------------------------+
| Search Global Database:  [ Enter email or name...        ] [Search]    |
| Found: ✓ Jane Lee (jane@orbit.io) - Previously at 3 events             |
| [ Use Existing Info ] or [ Register as New ]                           |
+------------------------------------------------------------------------+
| Quick Registration (if not found):                                     |
| Name *     [ Full Name                    ] Email  [ email@domain.com ] |
| Company    [ Company Name         ] Phone [ +1 555-xxx-xxxx    ]       |
| Status: (●) Walk-in  ( ) Pre-registered  ( ) Checked-in                |
| Actions: [ Cancel ]  [ Quick Register & Check-in ]                     |
+------------------------------------------------------------------------+
```

## 5B. Global Attendee Lookup
```
+------------------------ Global Attendee Search -------------------------+
| Search: [ jane@orbit.io                              ] [🔍 Search]      |
| Results:                                                                |
| +--------------------------------------------------------------------+  |
| | ✓ Jane Lee | jane@orbit.io | Orbit Labs | 3 events | Last: 2025-08 |  |
| | ✓ Jane Doe | jane@test.co  | TestCorp   | 1 event  | Last: 2025-07 |  |
| +--------------------------------------------------------------------+  |
| [ Select ] shows:                                                       |
| • Previous Events: Dev Summit 2024, Workshop Series                    |
| • Contact Info: Auto-filled from profile                               |
| • Preferences: Dietary restrictions, accessibility needs               |
| Actions: [ Add to Event ] [ View Full Profile ] [ Update Info ]         |
+------------------------------------------------------------------------+
```---------------------------------+
| ☰ Logo / Name                [ Search…                ]    🔔  ⟳ Sync  User ▼        Theme ○● |
+------------------------------------------------------------------------------------------------+
| Dashboard | Events | Members | Reports | Settings | Help                                       |
+-----------+------------------------------------------------------------------------------------+
| Breadcrumb: Home / Dashboard                                              Date: 2025-08-28     |
+------------------------------------------------------------------------------------------------+
| Status Summary (4-up)                                                                        ▲ |
| +----------------+ +----------------+ +----------------+ +----------------+                    |
| | Total Events   | | Active Events  | | Attendees      | | This Week      |                    |
| |        42      | |        18      | |        865     | |        7       |                    |
| +----------------+ +----------------+ +----------------+ +----------------+                    |
|                                                                                               |
| Upcoming Events (Next 5)                       [+ New Event]                                   |
| +--------------------------------------------------------------------------------------------+ |
| | • Dev Summit 2025       | 2025-09-03 | 240 / 400 | Active   | Manage ▸                     | |
| | • Product Launch        | 2025-09-09 | 120 / 250 | Draft    | Manage ▸                     | |
| | • Regional Meetup       | 2025-09-11 |  60 / 150 | Active   | Manage ▸                     | |
| | • Workshop Series Pt.1  | 2025-09-14 |  32 /  60 | Active   | Manage ▸                     | |
| | • Advisory Board Call   | 2025-09-16 |  18 /  25 | Pending  | Manage ▸                     | |
| +--------------------------------------------------------------------------------------------+ |
|                                                                                               |
| Recent Members                                                                                |
| +----------------------+-----------------------+--------------------+-----------------------+ |
| | Name                 | Company               | Added (UTC)        | Events (count)        | |
| +----------------------+-----------------------+--------------------+-----------------------+ |
| | Jane Lee             | Orbit Labs            | 2025-08-28 13:02   | 3                     | |
| | Carlos Santos        | IntraCloud            | 2025-08-28 12:55   | 1                     | |
| | Mia Park             | OpenForm              | 2025-08-28 12:41   | 2                     | |
| +--------------------------------------------------------------------------------------------+ |
| Quick Actions: [ + Event ] [ + Member ] [ Export CSV ] [ Reports ] [ Settings ]              |
+------------------------------------------------------------------------------------------------+
| Footer: © 2025 EventDeskPro · v1.0.0 · Keyboard: ? · API: OK (120ms)                           |
+------------------------------------------------------------------------------------------------+
```

## 2. Events List (With Bulk Actions)
```
+----------------------------------------------------------------------------------------------+
| Events                                   [ Search events… ] [ Status ▼ ] [ Export ▼ ]  (+)   |
+----------------------+------------+----------+-----------+------------+-----------+----------+
| ☐ (All)              | Name       | Date     | Status    | Capacity   | Reg (%)   | Actions  |
+----------------------+------------+----------+-----------+------------+-----------+----------+
| ☐                    | Dev Summit | 2025-09-03 | Active  | 400        | 60%       | ✏ 👁 ⧉ 🗑 |
| ☐                    | Workshop 1 | 2025-09-14 | Active  | 60         | 53%       | ✏ 👁 ⧉ 🗑 |
| ☐                    | Launch     | 2025-09-09 | Draft   | 250        | 48%       | ✏ 👁 ⧉ 🗑 |
| ☐                    | Meetup     | 2025-09-11 | Active  | 150        | 40%       | ✏ 👁 ⧉ 🗑 |
+----------------------------------------------------------------------------------------------+
| Bulk: [ Delete ] [ Duplicate ] [ Export CSV ] [ Mark Active ] [ Mark Draft ]                 |
| Pagination: « Prev | 1 | 2 | 3 | Next »   Rows per page: 25 ▼   Showing 1–25 of 62           |
+----------------------------------------------------------------------------------------------+
| Empty State (if none):  📂 No events yet – Create your first event [Create Event]             |
+----------------------------------------------------------------------------------------------+
```

## 2A. Members List (Global Database)
```
+----------------------------------------------------------------------------------------------+
| Members                             [ Search members… ] [ Company ▼ ] [ Export ▼ ]  (+)      |
+----------------------+------------------+------------------+--------------+------------------+
| ☐ (All)              | Name             | Email            | Company      | Events (count)   |
+----------------------+------------------+------------------+--------------+------------------+
| ☐                    | Jane Lee         | jane@orbit.io    | Orbit Labs   | 3 events         |
| ☐                    | Carlos Santos    | carlos@intra.io  | IntraCloud   | 1 event          |
| ☐                    | Mia Park         | mia@openform.dev | OpenForm     | 2 events         |
| ☐                    | John Smith       | john@tech.co     | TechCorp     | 5 events         |
+----------------------------------------------------------------------------------------------+
| Bulk: [ Email ] [ Add to Event ] [ Export CSV ] [ Delete ] [ Merge Duplicates ]              |
| Pagination: « Prev | 1 | 2 | 3 | Next »   Rows per page: 25 ▼   Showing 1–25 of 1,247        |
+----------------------------------------------------------------------------------------------+
| Global Member Database - All people who have ever registered for any event                   |
+----------------------------------------------------------------------------------------------+
```

## 3. Event Detail (Tabbed)
```
+----------------------------------------------------------------------------------------------+
| ← Back to Events      Dev Summit 2025                 [ Edit ] [ Duplicate ] [ ⋮ ]           |
| Status: ACTIVE  •  2025-09-03 09:00–17:00  •  Convention Center (Hall A)                     |
+----------------------------------------------------------------------------------------------+
| Tabs: Overview | Attendees | Schedule | Assets | Settings                                     |
+----------------------------------------------------------------------------------------------+
| Overview                                                                                (i)  |
| +----------------------+---------------------------+----------------------------------------+ |
| | Metrics              | Notes / Internal          | Tasks                                  | |
| | • Registrations 240  | • AV confirmed            | [ ] Finalize catering                  | |
| | • Capacity 400 (60%) | • Sponsor deck draft      | [ ] Print badges                       | |
| | • Checked-In 0       | • Waiting on keynote bio  | [x] Venue deposit                      | |
| +----------------------+---------------------------+----------------------------------------+ |
| Description:                                                                                    |
| “Annual developer summit focusing on distributed architecture and reliability.”                |
+----------------------------------------------------------------------------------------------+
```

### 3A. Event Detail → Attendees Tab (Enhanced Interactive Status Management)
```
Header Actions: [ + Add Attendee ] [ 👋 Walk-in ] [ Import CSV ] [ Export ] [ Send Emails ]

Attendance Summary (Real-time counts with clickable filters):
+----------------+ +----------------+ +----------------+ +----------------+
| Pre-Registered | Checked In     | Walk-ins       | Did Not Attend |
|       12       |       8        |       3        |       2        |
| (Blue)         | (Green)        | (Purple)       | (Gray)         |
+----------------+ +----------------+ +----------------+ +----------------+

+------------------------------------------------------------------------------+
| ☐ | Name           | Company    | Email              | Status Controls      |
+------------------------------------------------------------------------------+
| ☐ | Jane Lee       | Orbit Labs | jane@orbit.io      | [Pre-Reg] [✓Check] [DNA] |
| ☐ | Carlos Santos  | IntraCloud | carlos@intra.cloud | [Pre-Reg] [Checked-In] [DNA] |
| ☐ | Mike Johnson   | (Walk-in)  | mike@local.com     | [Walk-in] [✓Check] [DNA] |
| ☐ | Mia Park       | OpenForm   | mia@openform.dev   | [Pre-Reg] [✓Check] [DNA]  |
+------------------------------------------------------------------------------+

Status Button States & Transitions:
• Active status: [■ Pre-Registered] (solid background, bold)
• Inactive status: [□ Pre-Reg] (outline, hover effect)
• Colors: Blue (Pre-Registered), Purple (Walk-in), Green (Checked-In), Gray (DNA)

State Machine Rules:
• Pre-Registered ↔ Checked-In ↔ Did Not Attend
• Walk-In ↔ Checked-In ↔ Did Not Attend
• Undo Checked-In requires confirmation + reason
• DNA blocked before event end (unless manager override)

Bulk Actions: [ Mark Checked-In ] [ Mark DNA ] [ Send Emails ] [ Remove ] [ Export CSV ]
Real-time Updates: Status changes reflect immediately in summary cards
Auto-Rollover: Pre-Registered → DNA at event end + 3hr grace period
+------------------------------------------------------------------------------+
```

## 4. Add / Edit Event Form
```
+---------------------------------- Add New Event ----------------------------------+
| Name *                     [ Dev Summit 2025                               ]     |
| Date *        [ 2025-09-03 ]   Start * [ 09:00 ]  End * [ 17:00 ]                 |
| Location      [ Convention Center Hall A                                   ]     |
| Capacity      [ 400 ]   Status [ Active ▼ ]    Timezone [ UTC-05 ▼ ]             |
| Description   ┌───────────────────────────────────────────────────────────┐       |
|               | Annual developer summit...                                |       |
|               └───────────────────────────────────────────────────────────┘       |
| Advanced ▸ (Collapsible section)                                                  |
| Actions: [ Cancel ]                [ Save Event ] (disabled until valid)          |
+----------------------------------------------------------------------------------+
| Validation Hints (on error): “End time must be after start time.”                |
+----------------------------------------------------------------------------------+
```

## 5. Add Attendee Modal
```
+--------------------------- Add Attendee ----------------------------+
| First Name *  [ Jane ]          Last Name *   [ Lee ]               |
| Email *       [ jane@orbit.io ] Phone         [ +1 555 222 0199 ]   |
| Company       [ Orbit Labs ]    Tags          [ + Add Tag ]         |
| Assign to Events (multi-select):                                    |
| [x] Dev Summit 2025  [ ] Workshop 1  [x] Launch  [ ] Meetup         |
| Options: [x] Send confirmation   [ ] VIP                              |
| Errors (inline): “Email already exists” (if duplicate)              |
| Actions: [ Cancel ]        [ Add Attendee ]                         |
+---------------------------------------------------------------------+
```

## 6. Settings Page
```
+----------------------------------------------------------------------------------+
| Settings                                                  (User: admin@example ) |
+----------------------+-----------------------------------------------------------+
| General (●)          | Application Name        [ EventDeskPro            ]       |
| Localization         | Default Timezone        [ UTC-05 Eastern  ▼ ]            |
| Notifications        | Date Format             [ YYYY-MM-DD        ▼ ]          |
| Data & Export        | Time Format             [ 24h               ▼ ]          |
| Theming              | Theme                   ( ) Light (●) Dark ( ) Auto      |
|                      | Language                [ English (en)      ▼ ]          |
|                      |                                                             |
| Notifications:                                                              (i)  |
| [x] New registration emails   [x] Daily digest   [ ] Low capacity alerts          |
| Data & Export:                                                              (i)  |
| [ Export All Data ]  [ Import Data ]  [ Download Error Logs ]                    |
| Actions: [ Reset Unsaved ]                [ Save Settings ]                      |
+----------------------------------------------------------------------------------+
```

## 7. Responsive Mobile Examples

### 7A. Mobile Navigation (Collapsed)
```
┌──────────────────────────────┐
│ ☰  EventDeskPro        🔔 ⚙  │
├──────────────────────────────┤
│ Dashboard                    │
│ Events                       │
│ Members                      │
│ Reports                      │
│ Settings                     │
└──────────────────────────────┘
```

### 7B. Mobile Event Card List
```
[ + ]  Events
┌──────────────────────────────┐
| Dev Summit 2025              |
| 2025-09-03  •  240 / 400     |
| Status: Active               |
| [ View ]  [ Edit ]           |
└──────────────────────────────┘
┌──────────────────────────────┐
| Product Launch               |
| 2025-09-09  • 120 / 250      |
| Status: Draft                |
| [ View ]  [ Edit ]           |
└──────────────────────────────┘
```

## 8. Empty & Error States
```
EMPTY (Events):
┌─────────────────────────────────────────────┐
│ 📂 No events yet                            │
│ Create your first event to get started.     │
│ [ Create Event ]                            │
└─────────────────────────────────────────────┘

ERROR (Load Failure):
┌─────────────────────────────────────────────┐
│ ⚠️  Unable to load events                   │
│ Please check your connection and retry.     │
│ [ Retry ]   [ Report Issue ]                │
└─────────────────────────────────────────────┘
```

## 9. Component Anatomy (Reference)

### 9A. Button States
```
[ Default ]  [ Hover ]  [ Active ]  [ Disabled ]
Primary: bg-blue-600 / hover:blue-700 / active:blue-800 / opacity-50
Destructive: bg-red-600 / hover:red-700
Outline: border-gray-300 bg-white hover:bg-gray-50
```

### 9B. Form Field (States)
```
┌ Label ─────────────────────────────────────┐
| [ value                         ] (default) |
| [ value                ] ✱ (required)      |
| [ value                ] (error border red) |
|  Helper or error text                     |
└────────────────────────────────────────────┘
```

## 10. CSV Import/Export Operations

### 10A. Export Dialog (Enhanced)
```
+-------------------- Export Attendees ----------------------+
| Format: (●) CSV  ( ) JSON  ( ) PDF (coming soon)           |
| Scope:  (●) All  ( ) Filtered  ( ) Selected Only           |
| Include: [x] Names  [x] Email  [x] Company  [x] Status     |
|          [x] Phone  [x] Registration Date  [ ] Notes       |
| Actions: [ Cancel ]              [ Export CSV ]            |
+-----------------------------------------------------------+
```

### 10B. CSV Import Dialog
```
+-------------------- Import Attendees ----------------------+
| File: [ Choose CSV File... ] or [ Drop file here ]         |
| Preview (first 3 rows):                                    |
| +----------------------+------------------+-------------+  |
| | First Name | Last Name | Email          | Company     |  |
| +----------------------+------------------+-------------+  |
| | John       | Smith     | j@example.com  | TechCorp    |  |
| | Jane       | Doe       | jane@test.io   | StartupInc  |  |
| +----------------------+------------------+-------------+  |
|                                                            |
| Options: [x] Send welcome emails  [ ] Skip duplicates     |
| Status: ✓ 25 valid rows, ⚠ 2 duplicates found            |
| Actions: [ Cancel ]    [ Import 25 Attendees ]            |
+-----------------------------------------------------------+
```

### 10C. Export Dialog (Original Events)
```
+-------------------- Export Events ----------------------+
| Format: (●) CSV  ( ) JSON  ( ) PDF (coming soon)        |
| Scope:  (●) All  ( ) Filtered  ( ) Selected             |
| Include: [x] Attendees  [x] Capacity  [ ] Notes         |
| Actions: [ Cancel ]              [ Export ]             |
+--------------------------------------------------------+
```

## 11. Keyboard Shortcuts (Planned Overlay)
```
+---------------- Keyboard Shortcuts ----------------+
| ?              Open shortcuts overlay             |
| N (on Events)  New event                          |
| A (on Event)   Add attendee                       |
| /              Focus global search                |
| ESC            Close modal / panel                |
+---------------------------------------------------+
```

## 12. Data Flow (High-Level ASCII)
```
[ UI Components ] → (Actions) → [ View Models / Hooks ] → [ API Routes ] → [ DB Layer ]
      ↑                                                      ↓
  (Optimistic) ←──────── State Sync / Revalidation ──────────
```

## 14. Architecture: Members vs Attendees

### 14A. Clear Terminology
```
MEMBERS (Global Database):
• Location: Main Navigation → Members
• Purpose: Global database of ALL people across ALL events
• Use Case: Contact management, member profiles, cross-event analytics
• Example: "Jane Lee has attended 3 events total"

ATTENDEES (Event-Specific):
• Location: Event Detail → Attendees Tab
• Purpose: People registered/attending THIS specific event
• Use Case: Event check-in, status management, event logistics
• Example: "Jane Lee is checked-in to Dev Summit 2025"
```

### 14B. Workflow Integration
```
Walk-in Registration Workflow:
1. Person arrives → Search Members database (global lookup)
2. Found: Auto-fill from member profile → Add to THIS event's attendees
3. Not found: Create new member → Add to global database → Add to THIS event

Benefits:
• No duplicate data entry for returning members
• Rich member profiles with event history  
• Event-specific attendee management
• Clear separation of concerns
```

## 15. Validation Matrix (Summary)
```
Field           Required  Rules
--------------  --------  -----------------------------------------
Event Name      Yes       3–120 chars
Date            Yes       ISO date >= Today
Time (Start/End)Yes       end > start
Email           Yes       RFC basic pattern; unique
Capacity        Optional  Integer > 0
Status          Yes       Enum(draft|active|completed|cancelled)
```

## 15. Cross-Platform Implementation Notes

### 15A. React/Next.js Implementation (Web)
```
Platform: Web Browser (localhost:3001)
Features: ✅ Navigation ✅ Interactive Status Management ✅ CSV Export/Import
Architecture: Next.js 15.5.2 + SQLite + API Routes
Real-time: useState updates with optimistic UI
Status API: PATCH /api/attendees/[id] + bulk operations
```

### 15B. Swift/SwiftUI Implementation (macOS)
```
Platform: macOS Desktop Application 
Features: ✅ Navigation ✅ Interactive Status Management ✅ Real-time Data
Architecture: SwiftUI + GRDB + ObservableObject pattern
Components: AttendeeStatusRow + AttendeeStatusButton
Data Flow: DataManager → EventDetailView → Real-time UI updates
```

### 15C. Feature Parity Matrix
```
Feature                    React Web    Swift macOS    Status
-----------------------    ----------   -----------    --------
Event Navigation           ✅           ✅             Complete
Event Detail View          ✅           ✅             Complete  
Attendee Status (3-state)  ✅           ✅             Complete
Real-time Summary Cards    ✅           ✅             Complete
CSV Export                 ✅           🔄             In Progress
CSV Import                 ✅           🔄             In Progress
Responsive Design          ✅           N/A            Platform-specific
```

## 16. Status Management System (4-State Enhanced with Safeguards)

### 16A. Status States & Colors (Updated Vocabulary)

```
PRE-REGISTERED: Blue (#2563eb)     - Signed up ahead of time  
WALK-IN:        Purple (#8b5cf6)   - Registered on-site at event  
CHECKED-IN:     Green (#16a34a)    - Successfully attended event
DID NOT ATTEND: Gray (#6b7280)     - Absent after grace period (DNA)

Button States:
• Active:   [■ Pre-Registered] (solid background, bold text)
• Inactive: [□ Pre-Reg] (outline border, normal text, hover effect)
• Disabled: [⊘ DNA] (grayed out if event still in progress, unless override)
```

### 16B. State Transition Flow (Safeguarded State Machine)

```
Pre-Registered ↔ Checked-In ↔ Did Not Attend
             ↘               ↗              
Walk-in ↔ Checked-In ↔ Did Not Attend

Transition Rules & Safeguards:
• To Checked-In: Stamps checkedInAt timestamp (audit trail)
• From Checked-In: Requires confirmation dialog + audit reason
• To DNA before event end: Blocked unless manager override
• Auto-rollover: Pre-Registered → DNA at event end + 3hr grace
• Bulk DNA: Special confirmation for early DNA operations

Confirmation Patterns:
• Simple transitions: "Mark as Checked-In?" (✓ Confirm / Cancel)
• Undo check-in: "Provide reason" (required textarea)
• Early DNA: "Event still in progress" warning + override option
• Bulk early DNA: "Manager override required" confirmation
```

### 16C. Auto-Rollover & Scheduler Logic

```
Event Lifecycle Management:
1. During event: Normal status transitions allowed
2. At event end + 3hr grace: Auto-rollover job runs
   • Pre-Registered → Did Not Attend (DNA)
   • Checked-In remains unchanged
   • Walk-In → Did Not Attend (if not checked in)
3. Post-rollover: Manual corrections still allowed with audit

Configurable Settings:
• Grace period: 1-6 hours (default 3hrs)
• Early DNA: Manager override required (default ON)
• Auto-rollover: Can be disabled per event
• Audit retention: All status changes logged

Notifications:
• "12 attendees auto-marked as DNA after grace period"
• Email to event organizers with rollover summary
• Activity log: "Auto-rollover completed for Event XYZ"
```

### 16D. Enhanced Walk-in Workflow

```
Optimized for Event Day Speed:
1. Name + Email (optional) → Quick search existing members
2. Found: Auto-link member → Create attendee (Walk-in status)
3. Not found: Create member + attendee in one step
4. Option: Immediate check-in toggle for streamlined process

Member Database Integration:
• Search by email, name, or phone (fuzzy matching)
• Auto-fill company, tags from member profile
• Link to existing member prevents duplicates
• Member profile shows event history across all events

Data Quality Safeguards:
• Email deduplication at member level
• Prevent duplicate attendees per event
• Optional email for walk-ins (but encouraged)
• Phone number as backup identifier
```

## 17. Theming Tokens (Updated for New Status Colors)

```
Primary: #2563eb  | Primary Hover: #1d4ed8
Danger : #dc2626  | Danger Hover : #b91c1c
Warning: #d97706  | Success     : #16a34a
Radius : 6px      | Spacing Scale: 4 / 8 / 16 / 24 / 32

Status Colors (4-State System - Updated):
Pre-Registered: #2563eb (Blue)    | Hover: #1d4ed8
Walk-in:        #8b5cf6 (Purple)  | Hover: #7c3aed  
Checked-In:     #16a34a (Green)   | Hover: #15803d  
Did Not Attend: #6b7280 (Gray)    | Hover: #4b5563

Interaction States:
Active Button:   [■ Pre-Registered] (solid background, white text, bold)
Inactive Button: [□ Pre-Reg] (outline border, color text, hover effect)
Disabled Button: [⊘ DNA] (grayed out, reduced opacity, no interaction)
Confirmation:    Orange (#ea580c) for destructive confirmations
```

## 18. Implementation Status & Roadmap

### 18A. ✅ Phase 1: Navigation (COMPLETED)

- ✅ React: Event list, detail views, breadcrumbs
- ✅ Swift: Tab navigation, event detail, back navigation
- ✅ Cross-platform: Feature parity achieved

### 18B. ✅ Phase 2: Attendee Management (COMPLETED)

- ✅ React: Interactive 3-state buttons, real-time summary, CSV operations
- ✅ Swift: AttendeeStatusRow component, native status management
- ✅ Database: updateAttendeeStatus API, bulk operations support

### 18C. 🔄 Phase 3: Enhanced Attendee Workflow (CURRENT - SSOT DELTAS)

**§2.2 Attendee Status (REPLACE)**
- 🔄 Rename "Registered" → "Pre-Registered" across all UI
- 🔄 Replace "No Show" with "Did Not Attend (DNA)" in UI
- 🔄 Update status colors: Blue (Pre-Reg), Purple (Walk-in), Green (Checked-In), Gray (DNA)
- 🔄 Implement safeguarded state machine with confirmation dialogs
- 🔄 Add auto-rollover scheduler: Pre-Registered → DNA at event end + 3hr grace
- 🔄 Require audit reasons for undoing check-ins
- 🔄 Block early DNA unless manager override enabled

**§4.4 Event Detail → Attendees (AMEND)**
- 🔄 Header actions: [+ Add Attendee] [Walk-in] [Import CSV] [Export] [Send Emails]
- 🔄 Search-first Add Attendee workflow with member database integration
- 🔄 Minimal Walk-in registration (Name + optional Email)
- 🔄 Clickable status filter chips with real-time counts
- 🔄 Right-drawer edit panel (replace modal sheets)
- 🔄 Bulk actions with safeguards: [Mark Checked-In] [Mark DNA] [Remove]
- 🔄 Deep-linking from member profiles with highlight/scroll
- 🔄 Keyboard shortcuts: A (add), W (walk-in), / (search), Esc (close)

**§10.2 Attendees Acceptance Criteria (EXTEND)**
- 🔄 "Pre-Registered" terminology in all UI strings
- 🔄 Auto-DNA scheduler with audit trail and notifications
- 🔄 Confirmation patterns for all destructive actions
- 🔄 Member database integration prevents duplicate attendees
- 🔄 Table and Card views with identical functionality
- 🔄 Real-time status updates with optimistic UI
- 🔄 Cross-linking between Members and Event attendees

### 18D. 🔄 Phase 4: Advanced Features (OPTIONAL)

- 🔄 Email notification system for status changes
- 🔄 Advanced analytics and reporting
- 🔄 Bulk email campaigns to status groups
- 🔄 Export templates and custom fields

---

## 19. SSOT Authority & QA Checklist

### 19A. Vocabulary Standards (Authoritative)

```
CORRECT TERMS (use everywhere):
✅ Pre-Registered (not "Registered" or "Pre-reg")
✅ Walk-in (not "Walkin" or "Walk in")  
✅ Checked-In (not "Check in" or "Present")
✅ Did Not Attend (not "No Show" or "Absent")

STATUS CODES (database):
✅ "preregistered" | "walkin" | "checkedin" | "dna"
✅ Legacy "registered" → migrate to "preregistered"
✅ Legacy "noshow" → migrate to "dna"

MICRO-COPY STANDARDS:
✅ "Mark as Checked-In?" (confirmation)
✅ "Provide reason" (audit requirement)
✅ "Event still in progress" (early DNA warning)
✅ "Manager override required" (bulk early DNA)
```

### 19B. QA Validation Checklist

```
STATUS MANAGEMENT:
□ Pre-Registered → Checked-In (no confirmation required)
□ Checked-In → Pre-Registered (requires reason dialog)
□ Walk-in → Checked-In (no confirmation required)  
□ Any status → DNA (blocked if event in progress, unless override)
□ Bulk DNA before event end (requires manager confirmation)
□ Auto-rollover at event end + 3hr grace (with notifications)

ATTENDEE WORKFLOWS:
□ Add Attendee: Search members first, then create if not found
□ Walk-in: Minimal form (name required, email optional)
□ Duplicate prevention: Same member cannot be added twice to event
□ Member linking: Auto-link if email matches existing member
□ Status inheritance: New attendees default to Pre-Registered

UI/UX VALIDATION:  
□ Real-time count updates in status chips
□ Keyboard shortcuts work: A (add), W (walk-in), / (search)
□ Right-drawer edit panel (not modal)
□ Deep-linking from member profiles works
□ Bulk selection and actions functional
□ Responsive design maintained

DATA INTEGRITY:
□ All status changes create audit entries
□ checkedInAt timestamp on check-in
□ Undo reasons stored in audit log
□ Auto-rollover creates activity entries
□ Member database prevents email duplicates
```

---

**Last Updated:** 2025-08-28 7:45 PM EST  
**Implementation Status:** Phase 1 & 2 Complete → Phase 3 Enhanced Workflow Authority Established  
**Purpose:** Centralized visual reference for design, engineering, and QA with authoritative attendee workflow  
**Platforms:** React/Next.js 15.5.2 (Web) + Swift/SwiftUI 5.9 (macOS)  
**Authority Level:** SSOT - All teams must implement per these specifications
