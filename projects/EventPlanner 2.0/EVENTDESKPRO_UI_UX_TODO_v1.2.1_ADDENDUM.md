# EventDeskPro — UI/UX TODO v1.2.1 Addendum

This addendum reconciles v1.2 with clarified interaction contracts and adds a PR checklist.

## Deltas to v1.2 (paste into the main doc as acceptance bullets)
- Attendees chips & primary action: exclusive chip selection; ✓ only when Checked‑In selected; primary action swaps among Check‑In / Undo Check‑In / Revert to Pre‑Registered based on state.
- Member vs Event‑only badges: show person.crop.circle.badge.checkmark vs person.fill.badge.plus; VIP star is independent; include tooltips + VO labels.
- Filter bar semantics: expose as tablist; 1..5 select tabs (All, Pre‑Reg, Walk‑in, Checked‑In, DNA); per‑filter empty state when no results.
- Undo scope: last mutating status action (global queue), 30s window; `⌘Z` maps to Undo; toast includes “View Timeline” (stub).
- Bulk guard rules: Bulk DNA while event in progress requires Manager override (single confirmation); no‑op bulk disables Confirm.
- Pinned footer acceptance: footer baseline at window bottom at any size; single vertical scroll surface.
- Export parity: “Export” label everywhere; filenames include context + date + scope (e.g., `axxess_2025‑08‑30_attendees_filtered.csv`).
- Timezone UX: typing filters; Return selects highlighted; System pinned to top; invalid shows inline error; Save disabled until changes.
- Public Registration: enabling emits new URL/QR; Regenerate invalidates old links; Save PNG includes event name + date under QR.
- Accessibility focus: Esc closes; initial focus on primary field/button in sheets; add labels for badges and presence dot.

## PR Checklist (copy into Issues)
- [ ] Replace filter chips with text‑only FilterBar (tablist + 1..5 keys); add per‑filter empty states.
- [ ] Swap status chip row to exclusive AttendeeStatusChipGroup; enforce ✓ only for Checked‑In selected.
- [ ] Primary action button logic: Check‑In ↔ Undo Check‑In ↔ Revert to Pre‑Registered.
- [ ] Add Member/VIP badges to cards and table; tooltips + VO labels.
- [ ] Undo toast behavior: 30s window, `⌘Z` handler, optional “View Timeline” CTA.
- [ ] Bulk DNA guard: require Manager override in a single dialog; disable Confirm on no‑ops.
- [ ] Adopt AppScaffold on Events/Attendees/Members; verify one scroll + pinned footer.
- [ ] Unify Export/Import menus; ensure filenames include context + date + scope; respect PII gating.
- [ ] Timezone picker UX: search, Return selects, System pinned, inline error, Save on diff.
- [ ] Public Registration modal: enabling generates URL/QR, Regenerate warns/invalidates, Save PNG footer text.

## Implementation Notes (linking / FFI)
- Build a universal Rust static lib and link predictably, or package an `.xcframework` to avoid `unsafeFlags` and test‑time path issues.
- Ensure exported Rust functions are `#[no_mangle] pub extern "C" fn ...`.
- Consider pre‑build scripts to produce the universal lib for tests.

