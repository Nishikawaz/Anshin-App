#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$ROOT_DIR"
while [ ! -d "$REPO_DIR/.git" ] && [ "$REPO_DIR" != "/" ]; do
  REPO_DIR="$(dirname "$REPO_DIR")"
done

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "setup-hooks: .git directory not found in current or parent folders."
  exit 1
fi

HOOKS_DIR="$REPO_DIR/.git/hooks"
SOURCE_DIR="$ROOT_DIR/hooks"

mkdir -p "$HOOKS_DIR"

for hook in pre-commit pre-push commit-msg; do
  cp "$SOURCE_DIR/$hook" "$HOOKS_DIR/$hook"
  chmod +x "$HOOKS_DIR/$hook"
  echo "setup-hooks: installed $hook"
done

echo "setup-hooks: done."
