#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  usb-self-update.sh
#  Update Anthonyware repo on USB to latest from origin
#  Safe hard reset with submodule support
# ============================================================

echo "=== Anthonyware USB Self-Update ==="
echo

# Check if we're in a git repo
if [[ ! -d .git ]]; then
  echo "[ERROR] This directory is not a git repository."
  exit 1
fi

# Get current remote URL
REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "unknown")
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
CURRENT_COMMIT=$(git rev-parse HEAD --short 2>/dev/null || echo "unknown")

echo "[*] Current status:"
echo "    Remote: $REMOTE_URL"
echo "    Branch: $CURRENT_BRANCH"
echo "    Commit: $CURRENT_COMMIT"
echo

# Confirm before proceeding
echo "[WARNING] This will reset local changes and pull latest from origin/$CURRENT_BRANCH"
read -rp "Continue? [y/N] " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Update cancelled."
  exit 0
fi

echo

# Fetch from remote
echo "[*] Fetching from origin..."
if ! git fetch origin "$CURRENT_BRANCH"; then
  echo "[ERROR] Failed to fetch from origin"
  exit 1
fi

echo "[ OK ] Fetch complete"

# Reset to remote
echo "[*] Resetting to origin/$CURRENT_BRANCH..."
if ! git reset --hard "origin/$CURRENT_BRANCH"; then
  echo "[ERROR] Failed to reset to origin/$CURRENT_BRANCH"
  exit 1
fi

echo "[ OK ] Reset complete"

# Clean untracked files (optional)
echo "[*] Cleaning untracked files..."
git clean -fd

# Update submodules if any
echo "[*] Updating submodules..."
if git config --file .gitmodules --name-only --get-regexp path >/dev/null 2>&1; then
  git submodule update --init --recursive
  echo "[ OK ] Submodules updated"
else
  echo "[*] No submodules found"
fi

echo

# Show new status
NEW_COMMIT=$(git rev-parse HEAD --short)
NEW_TAG=$(git describe --tags --always 2>/dev/null || echo "no tag")

echo "=============================================="
echo "✓ Update complete"
echo "=============================================="
echo "New commit: $NEW_COMMIT"
echo "Tag:        $NEW_TAG"
echo

echo "Repository is now at latest origin/$CURRENT_BRANCH"
