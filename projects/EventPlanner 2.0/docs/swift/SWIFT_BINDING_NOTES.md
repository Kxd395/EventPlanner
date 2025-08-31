# Swift Binding Notes (using C FFI)
Last Updated: 2025-08-29 23:15:47Z

## Overview
The Rust core exposes a small C ABI (see `rust-core/include/eventdesk_core.h`). You can import this header into Swift via a bridging header or a SwiftPM system library target.

## Steps (Xcode project)
1) Build Rust lib as `cdylib` (already configured). Produce `libeventdesk_core.dylib` (or static `.a`).
2) Add the header and library to your Xcode target (Header Search Paths and Library Search Paths).
3) Create a bridging header (if using Swift app target) and `#include "eventdesk_core.h"`.
4) Call functions from Swift, mapping status codes to a Swift enum.

## Swift Enum & Wrapper Example
```swift
enum EDPStatus: Int32 { case preregistered = 0, walkin = 1, checkedin = 2, dna = 3 }

enum EDPTransitionCheck: Int32 { case ok = 0, needsReason = 1, needsManagerOverride = 2 }

func validateTransition(current: EDPStatus, new: EDPStatus, inProgress: Bool, override: Bool) -> EDPTransitionCheck {
  let res = edp_validate_transition(current.rawValue, new.rawValue, inProgress, override)
  return EDPTransitionCheck(rawValue: res) ?? .ok
}

func normalizeStatus(_ s: String) -> EDPStatus? {
  s.withCString { ptr in EDPStatus(rawValue: edp_normalize_status(ptr)) }
}

func autoRolloverDue(eventEnd: TimeInterval, grace: TimeInterval = 3*3600, now: TimeInterval = Date().timeIntervalSince1970) -> Bool {
  edp_auto_rollover_due(Int64(eventEnd), Int64(grace), Int64(now)) == 1
}

func coreVersion() -> String { String(cString: edp_core_version()) }
func isValidCanonicalStatus(_ s: String) -> Bool { s.withCString { edp_validate_status_code($0) == 1 } }
func listCanonicalCodes() -> [String] {
  (0..<Int(edp_ssot_status_count())).compactMap { idx in
    guard let c = edp_ssot_status_code_at(Int32(idx)) else { return nil }
    return String(cString: c)
  }
}
```

## CSV Preview Example
```swift
func csvPreview(jsonFrom csvText: String) -> String? {
  return csvText.withCString { ptr in
    guard let raw = edp_csv_preview_utf8(ptr) else { return nil }
    defer { edp_free_cstr(raw) }
    return String(cString: raw)
  }
}
```

## DB-backed CSV Commit Example
```swift
// Configure database path (e.g., app support directory)
let ok = "~/Library/Application Support/EventDeskPro/eventdesk.db".expandingTildeInPath
  .withCString { edp_set_db_path($0) == 1 }

// Commit directly for a specific event using CSV text
func csvCommitForEvent(eventId: String, csvText: String) -> String? {
  return eventId.withCString { eid in
    csvText.withCString { txt in
      guard let raw = edp_csv_commit_for_event(eid, txt) else { return nil }
      defer { edp_free_cstr(raw) }
      return String(cString: raw) // JSON {rowsImported, rowsErrored, duplicates}
    }
  }
}
```

## Reading Last Error
```swift
if let err = EDPCore.shared.lastError() {
  print("FFI error: \(err)")
}
```

## Analytics Validation/Emit Example
```swift
func analyticsEmit(json: String) -> Bool {
  json.withCString { ptr in edp_analytics_emit(ptr) == 1 }
}

func analyticsValidate(json: String) -> Bool {
  json.withCString { ptr in edp_analytics_validate(ptr) == 1 }
}
```

## File-backed Analytics Queue
```swift
// Configure a JSONL file path; subsequent edp_analytics_emit appends lines
let ok = EDPCore.shared.setAnalyticsPath("~/Library/Application Support/EventDeskPro/analytics.jsonl".expandingTildeInPath)
```

## Packaging
- For universal macOS support, build both `x86_64` and `arm64` Rust libs and use `lipo -create` to combine, or ship two slices.
- Sign and notarize the app and embedded library (see `docs/DEPLOYMENT.md`).
## Counts by Status
```swift
let counts = try EDPCore.shared.countsByStatus(eventId: "evt_1")
print(counts.preregistered, counts.walkin, counts.checkedin, counts.dna)
```

## CSV Export
```swift
let csv = try EDPCore.shared.csvExport(eventId: "evt_1")
```

## Auto-Rollover
```swift
let updated = edp_process_auto_rollover("evt_1", 1_700_000_000, Int64(Date().timeIntervalSince1970), 3*3600)
```

## List/Remove/Search/Walk-in
```swift
// List attendees
let attendees = try EDPCore.shared.listAttendees(eventId: "evt_1")

// Remove an attendee
let removed = EDPCore.shared.removeAttendance(attendanceId: attendees.first!.attendeeId, reason: "merge", changedBy: "swift")

// Search members
let members = try EDPCore.shared.searchMembers(query: "jane")

// Walk-in
let walkin = try EDPCore.shared.createWalkin(eventId: "evt_1", name: "Walk In", email: nil, phone: nil, company: "Orbit", immediateCheckin: true, changedBy: "swift")
```
