# EventDeskPro FFI Integration (Swift + Rust)
Last Updated: 2025-08-29 23:15:47Z

## Overview
The Rust core exposes a small C ABI in `rust-core/include/eventdesk_core.h`. You can import this header in Swift via a bridging header or a SwiftPM C target. Link the built Rust dylib (`libeventdesk_core.dylib`) into your app target.

## Build the Universal Rust Library
- Script: `scripts/build_universal.sh` (builds x86_64 + arm64 with `--features ffi`)
- Output: `rust-core/target/universal/libeventdesk_core.dylib`

## Xcode Integration (bridging header)
1) Add `rust-core/include/eventdesk_core.h` to your project (Headers path).
2) Add the universal dylib to your app target (Link Binary with Libraries).
3) Ensure the dylib is embedded and signed (Build Phases → Embed Frameworks or Copy Files phase).
4) Create a bridging header and add:
   ```c
   #include "eventdesk_core.h"
   ```
5) Call the FFI (see `docs/SWIFT_SAMPLE/EDPRustBridge.swift`).

Notes:
- `edp_status_to_str` and `edp_status_label` return static strings; DO NOT free them.
- `edp_csv_preview_utf8` returns a heap string you MUST free with `edp_free_cstr`.

## SwiftPM (optional)
You can also wrap the header in a C target (modulemap) and declare a product your app depends on. Consumers must ensure the dylib is available at link and runtime.

## Available FFI
- Status helpers: `edp_status_from_str`, `edp_status_to_str`, `edp_status_label`, `edp_normalize_status`
- Validation: `edp_validate_transition` (0=OK, 1=NeedsReason, 2=NeedsManagerOverride)
- Auto‑rollover: `edp_auto_rollover_due(event_end, grace, now)`
- CSV: `edp_csv_preview_utf8(csvText)`, `edp_csv_commit_preview_json(previewJson)` and `edp_free_cstr(ptr)`
- Analytics: `edp_analytics_validate(json)`, `edp_analytics_emit(json)` (no‑op emit with validation)

## Safety
- All strings are UTF‑8. Only free strings that are explicitly documented as heap‑allocated.
- Map status codes to Swift enums consistently; use canonical codes per `../ssot/SSOT.md`.
