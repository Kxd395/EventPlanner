#!/usr/bin/env bash
# Copies the built universal Rust dylib into the app bundle's Frameworks/lib folder
# Intended usage: add as a Run Script build phase in Xcode for the EventDeskProApp target.

set -euo pipefail

# SRCROOT is set by Xcode when running Build Phases. When running locally, assume repo root.
SRCROOT=${SRCROOT:-"$(cd "$(dirname "$0")/../.." && pwd)"}
BUILD_PRODUCTS_DIR=${BUILT_PRODUCTS_DIR:-"$SRCROOT/apps/EventDeskProApp/.build/debug"}
EXECUTABLE_FOLDER_PATH=${EXECUTABLE_FOLDER_PATH:-".build/debug"}

# Location of the universal dylib produced by scripts/build_universal.sh
UNIVERSAL_DYLIB_PATH="$SRCROOT/../../rust-core/target/universal/libeventdesk_core.dylib"

# Fallback: try local repo-relative path
if [ ! -f "$UNIVERSAL_DYLIB_PATH" ]; then
  UNIVERSAL_DYLIB_PATH="$SRCROOT/rust-core/target/universal/libeventdesk_core.dylib"
fi

if [ ! -f "$UNIVERSAL_DYLIB_PATH" ]; then
  echo "Error: universal dylib not found at $UNIVERSAL_DYLIB_PATH"
  echo "Build it with scripts/build_universal.sh or place libeventdesk_core.dylib at that path."
  exit 1
fi

# Destination inside the built app bundle
# @executable_path expects the dylib in Contents/MacOS/../lib at runtime; Xcode usually places frameworks in Frameworks/
APP_LIB_DIR="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Frameworks"

mkdir -p "$APP_LIB_DIR"
cp -f "$UNIVERSAL_DYLIB_PATH" "$APP_LIB_DIR/"
chmod 0644 "$APP_LIB_DIR/$(basename "$UNIVERSAL_DYLIB_PATH")"

echo "Copied $(basename "$UNIVERSAL_DYLIB_PATH") -> $APP_LIB_DIR"

# Optionally run install_name_tool to set rpath expectations (only if needed)
# install_name_tool -change @rpath/libeventdesk_core.dylib @executable_path/../Frameworks/libeventdesk_core.dylib "$APP_LIB_DIR/$(basename "$UNIVERSAL_DYLIB_PATH")"

exit 0
