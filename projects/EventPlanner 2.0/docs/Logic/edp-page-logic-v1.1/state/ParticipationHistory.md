# Participation History (v1.1)

Schema (concept)
```
participation_history (
  id uuid primary key,
  participant_id uuid not null,
  actor_user_id text,
  from_status text,
  to_status   text,
  from_payload jsonb,   -- e.g., { confirmed: true, checkedInAt: "..." }
  to_payload   jsonb,
  reason       text,
  created_at   timestamptz default now()
)
```

Core functions (Rust)
- set_participation_status(participant_id, new_status, actor, reason_opt, force_override: bool) -> ChangeId
- undo_last_change(participant_id, actor) -> ChangeId
- revert_to_change(change_id, actor, reason_opt) -> ChangeId
- remove_participant(participant_id, actor, reason_opt)
- fetch_history(participant_id) -> [Change]

Behavior
- All operations are atomic: write history row → update participant → publish UI event.
- Idempotency: setting same status no‑ops with benign result.

Bindings (Swift FFI)
- Mirror the four functions + fetch_history for timelines with Revert.
- Expose last error for UI banners.

UI wiring
- Keep an undo stack (participant_id, change_id, timestamp) for ⌘Z and toast Undo.
- Bulk operations apply changes per participant; surface consolidated toasts.

