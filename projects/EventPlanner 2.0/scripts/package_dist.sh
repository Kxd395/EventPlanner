#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT_DIR/dist"
LIBDIR="$ROOT_DIR/rust-core/target/universal"
HDRSRC="$ROOT_DIR/rust-core/include/eventdesk_core.h"

echo "Building universal Rust dylib..."
"$ROOT_DIR/scripts/build_universal.sh"

mkdir -p "$DIST/include" "$DIST/lib"
cp "$HDRSRC" "$DIST/include/"
cp "$LIBDIR/libeventdesk_core.dylib" "$DIST/lib/"

cat > "$DIST/README.txt" <<'EOF'
EventDeskPro Core Distribution
==============================

Files:
- include/eventdesk_core.h  (C FFI header for Swift bridging)
- lib/libeventdesk_core.dylib  (Universal macOS dylib, arm64+x86_64)

Usage:
1) Add header directory to Header Search Paths in Xcode.
2) Add the dylib to "Link Binary with Libraries" and ensure it's embedded & signed.
3) Import in Swift via bridging header: #include "eventdesk_core.h"
4) Or use the SwiftPM package wrapper `EventDeskCoreBindings` and add the dylib at the app level.

See docs/FFI_README.md for details.
EOF

echo "Packaged to: $DIST"

