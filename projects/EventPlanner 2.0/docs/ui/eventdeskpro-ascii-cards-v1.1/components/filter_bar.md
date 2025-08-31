# Text‑Only Filter Bar (v1.1)

Spec
- Labels: All · Pre‑Registered · Walk‑in · Checked‑In · DNA
- Style: text‑only buttons; selected = filled background (state color), bold label; unselected = 1‑pt outline.
- No counts or icons in the buttons. Counts appear in summary cards and Total label only.
- Keyboard: 1..5 map to each filter.
- Accessibility: treat as tabs; announce label and selected state.

ASCII
```
[ All ]  [ Pre‑Registered ]  [ Walk‑in ]  [ Checked‑In ]  [ DNA ]           Total: 214
```

Tokens
- Height 28–32pt; H padding 12
- Corner radius 8; 1‑pt outline when unselected
- Colors from status palette; “All” uses secondary when selected
