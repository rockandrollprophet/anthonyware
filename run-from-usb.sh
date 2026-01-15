#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  run-from-usb.sh
#  Entry point for USB-based installation
#  Sets REPO variable and runs master installer
# ============================================================

echo "=== Running Anthonyware Installer from USB ==="
echo

# Determine repository root
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[usb] Repository: $REPO"
echo "[usb] Starting installation..."
echo

# Verify installer exists
if [[ ! -f "$REPO/install-anthonyware.sh" ]]; then
  echo "[ERROR] install-anthonyware.sh not found at $REPO"
  exit 1
fi

# Check if running as root
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "[ERROR] This script must be run as root"
  exit 1
fi

# Export repo path for subprocesses
export REPO

# Run the master installer
exec bash "$REPO/install-anthonyware.sh"
