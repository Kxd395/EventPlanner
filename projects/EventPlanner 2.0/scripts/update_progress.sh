#!/usr/bin/env bash
set -euo pipefail

FILE="docs/progress/PROGRESS.md"
[ -f "$FILE" ] || { echo "Missing $FILE" >&2; exit 1; }

TS="$(date -u "+%Y-%m-%d %H:%M:%SZ")"

# Replace the timestamp marker
tmp=$(mktemp)
sed "s|Last Updated: <!--TIMESTAMP-->|Last Updated: ${TS}|" "$FILE" > "$tmp"
mv "$tmp" "$FILE"

echo "Updated $FILE at $TS"
