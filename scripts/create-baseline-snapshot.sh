#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  create-baseline-snapshot.sh
#  Create a baseline Timeshift snapshot for recovery
# ============================================================

echo "=== Creating Anthonyware Baseline Snapshot ==="
echo

if ! command -v timeshift >/dev/null; then
  echo "✗ Timeshift not installed."
  exit 1
fi

echo "This will create a baseline snapshot of your system."
echo "You can restore from this point with rollback-to-factory.sh"
echo

read -rp "Create baseline snapshot? [y/N] " ans
if [[ ! "$ans" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo "Creating snapshot..."
sudo timeshift --create --comments "Anthonyware OS 1.0 baseline" --tags D

if [[ $? -eq 0 ]]; then
  echo "✓ Baseline snapshot created successfully."
  echo
  echo "To restore: rollback-to-factory.sh"
else
  echo "✗ Failed to create snapshot."
  exit 1
fi
