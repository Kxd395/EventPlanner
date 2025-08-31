Xcode Build Fixes for EventDeskProApp
=====================================

Symptoms
- “Build input file cannot be found: …/Build/Products/Debug/CEventDeskCore.o”
- Undefined symbols for edp_* at link time

Root Causes
- Xcode expecting an object from the C target (header-only target) → missing .o
- Rust dylib architecture mismatch or not on linker/loader paths

Fixes in repo
- Added C sources so the C target always emits object files:
  - `Sources/CEventDeskCore/shim.c`
  - `Sources/CEventDeskCore/CEventDeskCore.c`
- SwiftPM linker paths include `rust-core/target/universal`/`debug`/`release`.

Steps to clean and rebuild
1) Product → Clean Build Folder (Shift+Cmd+K)
2) Xcode → Settings… → Locations → Derived Data → Delete project derived data
3) File → Packages → Reset Package Caches, then Resolve Package Versions
4) Build again

If typing beeps in all TextFields/TextEditors
- Ensure there are no bare letter shortcuts bound in the UI. Bare keys (e.g. "a", "w", "/") can intercept normal typing.
- In this repo, all such shortcuts have been removed or changed to Command‑modified equivalents. If you add new ones, prefer Command modifiers (e.g. Cmd+A) or use app‑level Command menus.
- Overlays and side panels can accidentally capture events. In this app, passive overlays don’t hit‑test, and the right drawer hides when a modal is presented.
- If it persists, clear Derived Data and re‑launch Xcode; then test typing in Settings → Organization Name.

Universal dylib (recommended)
```
rustup target add x86_64-apple-darwin aarch64-apple-darwin
scripts/build_universal.sh
```
Then re-run the app in Xcode. If runtime can’t find the dylib:
```
DYLD_LIBRARY_PATH=$(SRCROOT)/../../rust-core/target/universal
```
or copy the dylib in a Run Script phase to `@executable_path/../lib`.
