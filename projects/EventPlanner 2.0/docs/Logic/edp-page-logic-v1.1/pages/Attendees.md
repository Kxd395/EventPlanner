# Event → Attendees — Page Logic (v1.1)

## What you see
- Toolbar: + Add Attendee, 👋 Walk‑in, Import, Export, ✉ Send…, Search, Sort (Name/Status/Check‑in Time), View (Table|Cards).
- Text‑only Filter bar: All / Pre‑Registered / Walk‑in / Checked‑In / DNA. Single‑select; keyboard 1–5.
- Summary cards: 4‑up read‑only metrics (hidden on narrow widths).
- Capacity line.
- Cards grid or Table with: Name, Company, Email, presence dot, status chips, quick actions, and overflow (⋯) menu.
- Toast zone for instant Undo.
- Selection bar (when rows/cards selected) with bulk actions.

## Trigger → Logic → Outcome (TLO)

### Status change (chips or quick buttons)
| Trigger | Logic | Outcome |
|---|---|---|
| Set status to Checked‑In | Core validates; sets checkedInAt = now | Toast: “Checked‑In: {name} — [Undo] (30s)”; counts refresh; history row written |
| Set status to DNA | If event in progress → may require Manager + reason | Toast “Marked DNA: {name} — [Undo]”; counts refresh; history row written |
| Walk‑in → any | Same guards as above | Toast + history as above |

### Instant Undo (toast + ⌘Z)
| Trigger | Logic | Outcome |
|---|---|---|
| Click Undo in toast | undo_last_change(participant) | Restores exact prior state (status + timestamps + flags); counts refresh; history row “revert” |
| ⌘Z within 10 min | undo_last_change(lastChangedParticipant) | Same; if none, disabled |

### Row/Card overflow menu (⋯)
| Item | Logic | Outcome |
|---|---|---|
| Undo Check‑In… | If status == checkedIn → prompt reason if outside grace | Reverts to previous; clears checkedInAt if reverting that field; history row |
| Reset Participation… | Opens Reset dialog | Executes chosen option with guards; history row |
| Remove from Event… | Confirm removal | Unlink participant; counts refresh; history row |

### Bulk (selection bar)
| Item | Logic | Outcome |
|---|---|---|
| Undo Check‑In | Per‑row undo with consolidated result | Counts/rows update; history rows |
| Reset to Pre‑Registered | Batch update; reason may be required | Status preregistered; timestamps cleared; history rows |
| Remove from Event | Confirm; batch unlink | Rows removed; counts refresh; history rows |

## State & persistence
- Filter, Sort, View mode persisted per event.
- Undo stack (participant_id, change_id, timestamp) per window.
- Integration base URL `apiBase` for public registration sync.

## Guards & permissions
- Grace window 10 min: Staff can undo without reason.
- Beyond grace and post‑event: reason required; Manager role may be required.
- Early DNA during event: Manager unless within final N minutes (setting).

## Errors & empty
- Empty filter → “No attendees match this filter” with Clear link.
- Undo failure → toast explaining can’t undo; keep history entry intact.

## Analytics & audit
- Each mutation records actor, from→to, timestamps changed, reason (optional), and device.
- Undo produces a new history entry referencing reverted change.

