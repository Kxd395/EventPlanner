# Event → Attendees — Page Logic

## What you see
- Toolbar: **+ Add Attendee**, **👋 Walk‑in**, **Import**, **Export**, **✉ Send…**, **Search**, **Sort (Name/Status/Check‑in Time)**, **View (Table|Cards)**.
- Text‑only **Filter bar**: All / Pre‑Registered / Walk‑in / Checked‑In / DNA. Single‑select, keyboard 1‑5.
- Summary cards: 4‑up read‑only metrics (Pre‑Registered, Walk‑in, Checked‑In, DNA); hidden on narrow widths.
- Capacity line: `Capacity: X / Unlimited guests` (amber/red near limits).
- **Cards grid** (or Table): Each card shows **Name, Company, Email, presence dot**, **status chips**, and action buttons (**✓ Check‑In / Email / Remove**).

## Trigger → Logic → Outcome (TLO)

### Toolbar
| Trigger | Logic | Outcome |
|---|---|---|
| + Add Attendee | Open modal (search-first, dedupe by email/phone). Initial status radio; "Send confirmation"; "Add to Global Member Database" toggle. | New Attendee created and linked; counts refresh; audit "add". |
| 👋 Walk‑in | Minimal form (Name req; Email optional). Option "Register & Check‑In". | Create Attendee with status walkIn; optionally set checkedInAt now. |
| Import | CSV/JSON → Preview totals & errors; allows commit. | Adds/links attendees; errors.csv available; audit group entry. |
| Export | Menu formats & scope; PII gated by role. | Download; audit "export". |
| ✉ Send… | Bulk composer (uses filter/selection). | Emails queued/sent; audit "bulk email". |
| Search | Debounce; fuzzy on name/email/company/tags. | Grid updates; page resets. |
| Sort | Persist per event. | Reorder. |
| View mode | `attendees.viewMode` persisted. | Switch Table/Cards. |

### Filters
| Trigger | Logic | Outcome |
|---|---|---|
| Select “Checked‑In” | Set status predicate = checkedIn | Show only checked‑in cards; total shows count; export respects this by default. |

### Card: status chips (mutations)
| Trigger | Logic | Outcome |
|---|---|---|
| Pre‑Registered → ✓ Checked‑In | Immediate; set `checkedInAt = now()` | Dot turns green; counts & summaries update; audit entry written. |
| Walk‑in → ✓ Checked‑In | Immediate; set `checkedInAt = now()` | As above. |
| Any → DNA | If event in progress → Manager override + reason. Else allowed. | Status gray; counts update; audit includes reason/override. |
| Undo Checked‑In | Requires reason (modal). | Status reverts; `checkedInAt` cleared; audit with reason. |

### Card: action buttons
| Trigger | Logic | Outcome |
|---|---|---|
| ✓ Check‑In | If not checked-in → mark now. If already checked-in → same button toggles to **Undo** (requires reason). | Status & timestamps mutate; audit. |
| ✈ Email | Opens composer; respects opt-out. | Sent/queued; toast. |
| 🗑 Remove | Confirm; unlink attendee from this event (keep global member). | Row disappears; counts update; audit. |

## Validation & guards
- Email format if provided; dedupe by email/phone on add/import.
- Early DNA needs Manager role + reason.
- Remove while checked-in → extra confirmation.

## State & persistence
- Filter selection; Sort mode; View mode (AppStorage scoped: per event & tab).
- Integration base URL `apiBase` (Settings → Integration). Used for public registration sync.
- Local selection state for bulk actions; cleared on filter/sort change.

## Audit & analytics
- All status transitions log actor, from→to, timestamp, reason (if any).
- Summary tiles recompute from aggregates; no manual refresh needed.

## Errors & empty
- Empty filter shows “No attendees match this filter” with link to clear.
- Conflict on add/import shows dedupe merge UI.

## Realtime & sync
- While Attendees is open, the app pulls new public registrations:
  - Poll: GET `/api/events/:id/registrations?since=<unix>` every ~12s; merges via local csvCommit.
  - Push (optional): subscribe to SSE `/api/events/:id/registrations/stream` and apply events as they arrive.
- After merge, counts refresh and list updates idempotently.

## Accessibility & keyboard
- `A` add, `W` walk‑in, `/` search, `1..5` filters, `Esc` close modals.
- Filter bar is a tablist; status chips announce state (“Checked‑In, selected”).
