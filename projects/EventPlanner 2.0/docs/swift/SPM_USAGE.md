# Using EventDeskCoreBindings (SwiftPM)
Last Updated: 2025-08-29 23:15:47Z

## Add Package
- In Xcode, File → Add Packages… → Add local package (select repo root containing `Package.swift`).
- Add product `EventDeskCoreBindings` to your app target.

## Link the Rust dylib
SwiftPM cannot build the Rust dylib. Build and embed it at the app level:

1) Build universal dylib:
```
./scripts/build_universal.sh
```
Outputs: `rust-core/target/universal/libeventdesk_core.dylib`

2) Embed & sign
- Add the dylib to "Link Binary with Libraries".
- Add a Copy Files (Frameworks) build phase or "Embed Frameworks" so it is bundled with the app.

3) Runtime search path
- Ensure your app’s runtime can load the dylib (default when embedded in app bundle).

## Import and Use
```swift
import EventDeskCoreBindings

let core = EDPCore.shared
print(core.version)
let ok = try core.validateTransition(current: "preregistered", new: "checkedin", inProgress: false, override: false)
```

## Alternatives
- Use a bridging header instead of SPM (see `docs/FFI_README.md`).
