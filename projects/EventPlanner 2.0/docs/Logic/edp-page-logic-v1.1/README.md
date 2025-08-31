# EventDeskPro — Page Logic Pack (v1.1)
Generated: 2025-08-31 22:10:00Z

Scope of v1.1
- Adds reversible participation flows (Undo / Reset) across Attendees (instant toast, row menu, bulk).
- Documents participation history model + core APIs + bindings.
- Wires keyboard Undo (⌘Z) within a grace window.
- Keeps v1.0 content (filters, cards/table, QR modal) and builds on it.

Contents
- pages/Attendees.md — UI + TLO mappings for instant undo, row menu, bulk reset.
- modals/ResetParticipation.md — Dialog options, guards, copy.
- state/ParticipationHistory.md — Schema + core functions + FFI.
- components/Commands.md — Keyboard and selection bar behaviors.
- qa/Acceptance.md — End-to-end checks.

Ground rules
- Single scroll surface, pinned footer, text-only filter bar.
- Reversibility: every mutation writes history and can be reverted.
- Audit: all actions include actor, time, reason (when required).

