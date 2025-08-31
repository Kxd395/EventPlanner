# Building a universal macOS dylib for EventDesk core
Last Updated: 2025-08-29 23:15:47Z

This document explains how to produce a universal (x86_64 + arm64) dynamic library for the Rust core used by the Swift app.

## Option 1 (recommended): Build universal dylib (requires rustup)

Prerequisites

- Xcode command line tools (clang, lipo, xcrun)
- Rust toolchain via `rustup`

Steps

1. Add macOS targets:

   rustup target add x86_64-apple-darwin aarch64-apple-darwin

2. From the repository root, run the helper script:

   scripts/build_universal.sh

3. The generated universal dylib will be at `rust-core/target/universal/libeventdesk_core.dylib`.

4. Rebuild the Swift app to link the new library:

   cd apps/EventDeskProApp && swift build -c debug

Notes

- The script will try to detect and add missing rust targets if `rustup` is available.
- If `lipo` is not in PATH, the script will try `xcrun lipo`.

## Option 2: Build app for arm64 on an Apple Silicon host

If you are on an Apple Silicon machine and prefer to build the Swift app for arm64 instead of creating a universal dylib, build the app either in Xcode or via the Swift Package Manager forcing the architecture.

- Build in Xcode and select a native arm64 run destination.
- Or, when available on your host, run:

  arch -arm64 swift build -c debug

## Next steps after linking

- Finish status-change dialogs with manager override enforcement and undo pattern.
- Add return anchor navigation (profile -> back to highlighted attendee).
- Add report stubs (check-in curve / no-show) and back them with basic data.
- Add SwiftUI smoke tests (non-FFI) and start gating in CI.
