#!/usr/bin/env bash
# format-all.sh - Format all bash scripts with shfmt

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORMATTED=0

echo "Formatting all scripts with shfmt..."
echo

if ! command -v shfmt >/dev/null 2>&1; then
  echo "ERROR: shfmt not installed"
  echo "Install with: pacman -S shfmt"
  exit 1
fi

# Format with 2-space indentation, simplify, align switches
SHFMT_ARGS="-i 2 -s -ci"

# Format install scripts
echo "Formatting install scripts..."
while IFS= read -r script; do
  echo "  Formatting $(basename "$script")..."
  shfmt $SHFMT_ARGS -w "$script"
  ((FORMATTED++))
done < <(find "$REPO_ROOT/install" -name "*.sh" -type f)

# Format library scripts
echo "Formatting library scripts..."
while IFS= read -r script; do
  echo "  Formatting $(basename "$script")..."
  shfmt $SHFMT_ARGS -w "$script"
  ((FORMATTED++))
done < <(find "$REPO_ROOT/install/lib" -name "*.sh" -type f 2>/dev/null)

# Format utility scripts
echo "Formatting utility scripts..."
while IFS= read -r script; do
  echo "  Formatting $(basename "$script")..."
  shfmt $SHFMT_ARGS -w "$script"
  ((FORMATTED++))
done < <(find "$REPO_ROOT/scripts" -name "*.sh" -type f 2>/dev/null)

echo
echo "✓ Formatted $FORMATTED script(s)"
