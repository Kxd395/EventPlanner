# Deployment Guide (macOS SwiftUI + Rust Core)
Last Updated: 2025-08-29 23:15:47Z

## Prereqs
- Xcode (latest), Rust toolchain (stable), codesign identity (Developer ID), Apple notarization access.

## Build Steps (local)
1) Rust core
   - `cargo build --release`
   - Produce universal lib (if needed): build for `aarch64-apple-darwin` and `x86_64-apple-darwin`, then `lipo -create` → `libeventdesk_core_universal.a`
2) Swift app
   - Link Rust lib via SPM/Xcode project settings.
   - Archive with Release configuration.

## Code Signing & Notarization
1) Sign app and embedded Rust lib with the same identity.
2) Create notarization pkg (Xcode Organizer or `xcrun altool` / `notarytool`).
3) Staple the ticket and verify.

## Packaging
- DMG or ZIP with app bundle, README, LICENSE, and version notes.
- Include `PRIVACY.md` describing analytics boundaries (PII only inside `pii`).

## Release Checklist
- [ ] Migrations applied at first run and reversible (backup).
- [ ] Status transitions validated with safeguards.
- [ ] Analytics events validate against schema and redact PII.
- [ ] Crash/error logs do not contain PII.
- [ ] A11y/keyboard shortcuts verified on primary flows.
- [ ] Versioned artifacts, signed, and notarized.
