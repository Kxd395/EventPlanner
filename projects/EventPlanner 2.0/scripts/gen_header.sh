#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CRATE_DIR="$ROOT_DIR/rust-core"
OUT_DIR_RS="$CRATE_DIR/include"
OUT_DIR_SWIFT="$ROOT_DIR/Sources/CEventDeskCore/include"

if ! command -v cbindgen >/dev/null 2>&1; then
  echo "cbindgen not found. Install with: cargo install cbindgen" >&2
  exit 2
fi

mkdir -p "$OUT_DIR_RS" "$OUT_DIR_SWIFT"

echo "Generating C header from Rust with cbindgen..."
cbindgen --config "$CRATE_DIR/cbindgen.toml" --crate eventdesk_core --crate-dir "$CRATE_DIR" --output "$OUT_DIR_RS/eventdesk_core.h"

echo "Copying header to Swift include path..."
cp -f "$OUT_DIR_RS/eventdesk_core.h" "$OUT_DIR_SWIFT/eventdesk_core.h"
echo "Done: $OUT_DIR_SWIFT/eventdesk_core.h"

