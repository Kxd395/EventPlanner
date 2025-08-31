# Undo Toast (v1.1)

Behavior
- Appears after status mutations (Check‑In, DNA, etc.), lives for 30s.
- Shows action + name and an Undo action.
- ⌘Z triggers the same undo while the toast is visible (and within grace window).

ASCII
```
──────────────────────────────────────────────────────────────────────────
Checked‑In: Kevin Dial    [ Undo ]                             00:28
──────────────────────────────────────────────────────────────────────────
```

Notes
- Place above pinned footer; span width; do not obscure primary controls.
- Multiple changes queue; the most recent is actionable with ⌘Z.
