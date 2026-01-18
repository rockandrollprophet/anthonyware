#!/usr/bin/env bash
# shellcheck-all.sh - Run shellcheck on all bash scripts

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURES=0

echo "Running shellcheck on all scripts..."
echo

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "ERROR: shellcheck not installed"
  echo "Install with: pacman -S shellcheck"
  exit 1
fi

# Check install scripts
echo "Checking install scripts..."
while IFS= read -r script; do
  echo "  Checking $(basename "$script")..."
  if ! shellcheck -x "$script"; then
    ((FAILURES++))
  fi
done < <(find "$REPO_ROOT/install" -name "*.sh" -type f)

# Check library scripts
echo
echo "Checking library scripts..."
while IFS= read -r script; do
  echo "  Checking $(basename "$script")..."
  if ! shellcheck -x "$script"; then
    ((FAILURES++))
  fi
done < <(find "$REPO_ROOT/install/lib" -name "*.sh" -type f 2>/dev/null)

# Check utility scripts
echo
echo "Checking utility scripts..."
while IFS= read -r script; do
  echo "  Checking $(basename "$script")..."
  if ! shellcheck -x "$script"; then
    ((FAILURES++))
  fi
done < <(find "$REPO_ROOT/scripts" -name "*.sh" -type f 2>/dev/null)

echo
if [[ $FAILURES -eq 0 ]]; then
  echo "✓ All scripts passed shellcheck"
  exit 0
else
  echo "✗ $FAILURES script(s) failed shellcheck"
  exit 1
fi
