#!/bin/bash

set -euo pipefail

TARGET=${1:-gemini}
SCOPE=${2:-local}
SKILL_NAME="news-verify"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/skill/$TARGET"

if [ "$TARGET" != "gemini" ]; then
  echo "Error: unsupported target '$TARGET'"
  echo "Usage: ./install.sh gemini [local|user]"
  exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: source directory not found: $SOURCE_DIR"
  exit 1
fi

if [ "$SCOPE" = "local" ]; then
  WORKSPACE_ROOT="${LOCAL_AGENT_WORKSPACE:-$PWD}"
  DEST_DIR="$WORKSPACE_ROOT/.gemini/skills/$SKILL_NAME"
elif [ "$SCOPE" = "user" ]; then
  DEST_DIR="$HOME/.gemini/skills/$SKILL_NAME"
else
  echo "Error: unsupported scope '$SCOPE'"
  echo "Usage: ./install.sh gemini [local|user]"
  exit 1
fi

echo "Installing $SKILL_NAME to Gemini workspace..."
echo "Scope: $SCOPE"
echo "Source: $SOURCE_DIR"
echo "Destination: $DEST_DIR"

mkdir -p "$DEST_DIR"

if command -v rsync >/dev/null 2>&1; then
  rsync -av --delete --exclude='.*' "$SOURCE_DIR/" "$DEST_DIR/"
else
  rm -rf "$DEST_DIR"
  mkdir -p "$DEST_DIR"
  cp -R "$SOURCE_DIR/"* "$DEST_DIR/"
fi

echo "Install complete."
echo "Run '/skills reload' inside Gemini CLI to reload skills."
