#!/usr/bin/env bash
set -euo pipefail

# Copy universal dylib next to the built app's lib folder for runtime lookup.
# Use in Xcode Run Script phase with "Run script only when installing" unchecked.

SRC_ROOT="${SRCROOT:-$(pwd)}"
TARGET_DIR="${TARGET_BUILD_DIR:-$SRC_ROOT}/../lib"
DYLIB_SRC="$SRC_ROOT/../../rust-core/target/universal/libeventdesk_core.dylib"

mkdir -p "$TARGET_DIR"
if [ ! -f "$DYLIB_SRC" ]; then
  echo "Universal dylib not found at $DYLIB_SRC" >&2
  exit 0
fi
cp -f "$DYLIB_SRC" "$TARGET_DIR/"
echo "Copied libeventdesk_core.dylib to $TARGET_DIR"

