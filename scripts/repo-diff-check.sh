#!/usr/bin/env bash
set -euo pipefail

echo "=== Anthonyware Repo Diff Checker ==="

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPO_ROOT"

# Expected files (relative paths), driven by git ls-files for accuracy
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$REPO_ROOT" ls-files | sort > /tmp/anthonyware-expected.txt
else
  # Fallback: mirror the previous behavior with maxdepth 5
  find . -maxdepth 5 -type f \
    | sed 's|^\./||' \
    | sort > /tmp/anthonyware-expected.txt
fi

# Actual files (bounded depth to avoid noisy extras)
find . -maxdepth 5 -type f \
  | sed 's|^\./||' \
  | sort > /tmp/anthonyware-actual.txt

echo
echo "--- Missing files (expected but not found) ---"
comm -23 /tmp/anthonyware-expected.txt /tmp/anthonyware-actual.txt || true

echo
echo "--- Extra files (present but not in expected list) ---"
comm -13 /tmp/anthonyware-expected.txt /tmp/anthonyware-actual.txt || true

echo
echo "=== Repo diff check complete ==="