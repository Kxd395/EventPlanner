# Modal — Reset Participation (v1.1)

Title: Reset Participation — {Full Name}

Options (radio)
- Revert to previous status (shows “From: {from} → {to} at {time}”).
- Set to Pre‑Registered (clear checkedInAt, dnaAt; confirmed=false).
- Mark Cancelled (excluded from metrics; optional note).
- Remove from this event (unlink participant only; keep global member).

Fields
- Reason (required if outside grace window or if event ended).
- [x] Email attendee about this change (optional; respects opt‑out).

Buttons
- Cancel · Reset

Microcopy
- “This action updates counts immediately and is fully auditable.”

Guardrails & permissions
- Grace window: 10 minutes after a change → no reason required; Staff can undo.
- Beyond grace / event ended: reason required; Manager role to override.
- Early DNA while event in progress: Manager unless within final N minutes (setting).

State changes & side‑effects
| Action | Effect |
|---|---|
| Undo Check‑In | status → previous; clear checkedInAt if reverting; counts update |
| Set Pre‑Registered | status → preregistered; checkedInAt/dnaAt null; confirmed=false |
| Mark Cancelled | status → cancelled; excluded from metrics |
| Remove from Event | delete participant row; keep global member |

Audit
- Every action writes a participation_history row and emits an audit entry (user, time, reason).

