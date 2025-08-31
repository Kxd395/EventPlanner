#!/usr/bin/env bash
set -euo pipefail

# Build universal macOS dylib for Rust core (x86_64 + arm64)
cd "$(dirname "$0")/.."

CRATE_DIR="rust-core"
OUT_DIR="$CRATE_DIR/target/universal"
mkdir -p "$OUT_DIR"

# FEATURES can be exported in the environment, default to `ffi` if not set
FEATURES=${FEATURES:-ffi}

REQUIRED_TARGETS=("x86_64-apple-darwin" "aarch64-apple-darwin")

echo "Checking for cargo..."
if ! command -v cargo >/dev/null 2>&1; then
	echo "cargo not found in PATH. Install Rust from https://rustup.rs and try again." >&2
	exit 2
fi

echo "Checking rustup (optional)..."
if command -v rustup >/dev/null 2>&1; then
	for t in "${REQUIRED_TARGETS[@]}"; do
		if ! rustup target list --installed | grep -q "^${t}$"; then
			echo "Adding missing rust target: ${t}"
			rustup target add "${t}"
		fi
	done
else
	echo "rustup not found: if cross-compilation fails, install rustup and add targets: ${REQUIRED_TARGETS[*]}"
fi

echo "Building release for targets: ${REQUIRED_TARGETS[*]} (features: $FEATURES)"
for target in "${REQUIRED_TARGETS[@]}"; do
	echo "Building for ${target}..."
	cargo build --release --features "$FEATURES" --manifest-path "$CRATE_DIR/Cargo.toml" --target "$target"
done

LIBNAME=libeventdesk_core.dylib
X86="$CRATE_DIR/target/x86_64-apple-darwin/release/$LIBNAME"
ARM="$CRATE_DIR/target/aarch64-apple-darwin/release/$LIBNAME"
UNIV="$OUT_DIR/$LIBNAME"

if [ ! -f "$X86" ]; then
	echo "Expected x86 library not found: $X86" >&2
	exit 3
fi
if [ ! -f "$ARM" ]; then
	echo "Expected arm64 library not found: $ARM" >&2
	exit 3
fi

echo "Creating universal binary: $UNIV"
if command -v lipo >/dev/null 2>&1; then
	lipo -create -output "$UNIV" "$X86" "$ARM"
else
	echo "lipo not found. On modern macOS you can use `lipo`, or use `xcrun lipo`. Trying xcrun..."
	xcrun lipo -create -output "$UNIV" "$X86" "$ARM"
fi

echo "Setting executable permissions on $UNIV"
chmod 755 "$UNIV"

echo "Regenerating C header via cbindgen (if available)..."
if command -v cbindgen >/dev/null 2>&1; then
    "$PWD/scripts/gen_header.sh" || true
else
    echo "cbindgen not installed; skipping header regeneration."
fi

echo "Done: $UNIV"
