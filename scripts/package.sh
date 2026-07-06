#!/usr/bin/env bash
set -euo pipefail

# Package the Knockoff extension into a zip for Chrome Web Store upload.
# Usage: ./scripts/package.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION=$(node -e "console.log(require('$ROOT_DIR/manifest.json').version)")
ZIP_NAME="knockoff-v${VERSION}.zip"
ZIP_PATH="$ROOT_DIR/$ZIP_NAME"

echo "Packaging Knockoff v${VERSION}..."

rm -f "$ZIP_PATH"

cd "$ROOT_DIR"
zip -r "$ZIP_PATH" manifest.json src data options icons -x "*.DS_Store"

echo "Created $ZIP_PATH"
