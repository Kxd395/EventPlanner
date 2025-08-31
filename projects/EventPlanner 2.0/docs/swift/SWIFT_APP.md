# SwiftUI App (SPM) – EventDeskProApp
Last Updated: 2025-08-29 23:15:47Z

A minimal SwiftUI macOS shell that links to `EventDeskCoreBindings` and demonstrates loading/creating events.

## Build
```
cd apps/EventDeskProApp
swift build -c release
```

## Run (from Xcode)
- Open the folder `apps/EventDeskProApp` in Xcode and run the executable target `EventDeskProApp`.

## What it does
- Configures database and analytics file paths under Application Support
- Shows version string from FFI
- Lists events and lets you create a Sample Event (writes to DB)
- Navigate into an Event to see: Overview and Attendees tabs
- Attendees: search + sorting, status filter chips with counts; multi-select with bulk actions (check-in/DNA/remove);
  context menu actions per row; CSV export; CSV import (preview + commit) with errors CSV download + duplicates
- Walk‑in modal; Member Profile modal with event history; Settings (theme/timezone)
- Command Palette (⌘⇧P), Shortcuts overlay; emits analytics events for key actions

## Next (wiring)
- Status change dialog (reason/override) and bulk updates
- Deep-link highlight + return anchor (see NAVIGATION.md)
- Keyboard shortcuts: A (Add), W (Walk‑in), / (Search)
 - Hook theme setting to macOS appearance (done)
 - Add remove confirmation + undo (partially done)
