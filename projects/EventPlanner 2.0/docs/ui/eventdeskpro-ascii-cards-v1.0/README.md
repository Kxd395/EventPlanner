EventDeskPro — ASCII Cards v1.0
Last Updated: 2025-08-31 13:45:00Z

Purpose
- Define compact, read-only “metric cards” used in Attendees to show status totals.
- Provide ASCII layouts, visual tokens, and behavior rules for consistent UI.

Scope
- Metric Summary Cards (Pre‑Registered, Walk‑in, Checked‑In, DNA)
- Responsive behavior (hide on small widths)
- Non-interactive (cards do not filter)

Visual Tokens
- Card background: macOS .thinMaterial (or neutral surface)
- Title: caption, secondary color
- Count: title2, bold, primary color
- Status dot: 8×8 circle, uses status color
- Radius: 8
- Spacing: 12 outer padding; 6 between title and count row

Status Colors (EDPDesign)
- preregistered: Blue
- walkin: Purple
- checkedin: Green
- dna: Gray

ASCII — 4-Up Summary
```
+----------------+  +--------------+  +----------------+  +---------+
| Pre-Registered  |  | Walk-in      |  | Checked-In     |  | DNA     |
|      128    ●   |  |     42   ●   |  |     210   ●    |  |   18 ●  |
+-----------------+  +--------------+  +-----------------+  +---------+
```

Notes
- The dot ● is filled with the status color; count is primary text.
- Titles are left-aligned; counts align left with a small gap to the dot.
- Cards stretch to equal widths within the row.

Responsive Rule
- Hide the entire 4-up card row when container width < 640pt.
- When hidden, the Attendees header retains the text-only filter bar and capacity line.

Behavior
- Cards are read-only metrics and do not filter.
- Keyboard focus skips the cards (no interactive elements inside).
- Screen readers announce the card’s title and count as a single label.

Accessibility
- Each card exposes an accessibilityLabel like “Pre‑Registered: 128”.
- The row has role none (it is purely informational).

Empty/Zero States
- Always show cards when width allows, even if some counts are zero.
- Do not dim or disable: zero values are valid metrics.

Implementation Pointers
- View: apps/EventDeskProApp/Sources/Views/Attendees/AttendeeSummaryCards.swift
  - GeometryReader hides the row < 640pt (see `hide` flag).
  - SummaryCard uses .thinMaterial, cornerRadius 8, and an 8×8 color dot.

Acceptance Checklist
- Cards render with titles and counts; status dot reflects correct color.
- Cards are non-interactive and do not affect filters.
- At narrow widths the row is hidden; layout does not jump.
- VoiceOver announces “<Title>: <Count>” for each card.

