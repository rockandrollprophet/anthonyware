#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  rollback-to-factory.sh
#  Restore to baseline Timeshift snapshot
# ============================================================

echo "╔════════════════════════════════════════════════════╗"
echo "║ Anthonyware Rollback to Factory Settings           ║"
echo "╚════════════════════════════════════════════════════╝"
echo
echo "This will restore your system to a baseline snapshot."
echo "All changes since that snapshot will be lost."
echo

read -rp "Type YES to continue: " ans
if [[ "$ans" != "YES" ]]; then
  echo "Aborted."
  exit 0
fi

if ! command -v timeshift >/dev/null; then
  echo "✗ Timeshift not installed."
  exit 1
fi

echo
echo "Available snapshots:"
echo "════════════════════"
sudo timeshift --list

echo
echo
read -rp "Enter snapshot number to restore (or press Ctrl+C to abort): " SNAP

if [[ -z "$SNAP" ]]; then
  echo "No snapshot selected."
  exit 1
fi

echo
echo "Restoring from snapshot $SNAP..."
sudo timeshift --restore --snapshot "$SNAP"

if [[ $? -eq 0 ]]; then
  echo "✓ Restoration initiated. Follow on-screen prompts."
  echo "  System will reboot automatically."
else
  echo "✗ Restoration failed. See timeshift logs for details."
  exit 1
fi
