#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Searching for references to CEventDeskCore.o in project files..."
rg -n "CEventDeskCore\.o" "$ROOT_DIR" || {
  echo "No references found.";
  exit 0;
}

echo "If any .o references appear in Xcode project files, remove them from Build Phases."

