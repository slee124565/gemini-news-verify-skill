#!/bin/bash

set -euo pipefail

TARGET=${1:-gemini}
SKILL_NAME="news-verify"
SOURCE_DIR="./skill/$TARGET"

if [ "$TARGET" != "gemini" ]; then
  echo "Error: unsupported target '$TARGET'"
  echo "Usage: ./release.sh gemini"
  exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: source directory not found: $SOURCE_DIR"
  exit 1
fi

VERSION=$(grep '^version:' "$SOURCE_DIR/SKILL.md" | head -n 1 | awk '{print $2}' | tr -d '\r')
if [ -z "$VERSION" ]; then
  VERSION="unknown"
fi
VERSION=${VERSION#v}

OUTPUT="./${SKILL_NAME}-${TARGET}-v${VERSION}.zip"

echo "Packaging $SKILL_NAME ($TARGET) -> $OUTPUT"
(
  cd "$SOURCE_DIR" || exit 1
  zip -r "../../$(basename "$OUTPUT")" ./* > /dev/null
)

echo "Created: $OUTPUT"
