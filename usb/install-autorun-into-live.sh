#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  install-autorun-into-live.sh
#  Install autorun service into the Arch live environment
#  Run this once on first boot from USB with Arch ISO
# ============================================================

echo "[autorun-setup] Installing autorun service into live environment..."

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "ERROR: This script must be run as root (sudo)." >&2
  exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "[autorun-setup] Repository: $REPO_ROOT"

# Copy service file
if [[ -f "$SCRIPT_DIR/autorun.service" ]]; then
  cp "$SCRIPT_DIR/autorun.service" /etc/systemd/system/anthonyware-usb-autorun.service
  echo "[autorun-setup] ✓ Service installed to /etc/systemd/system/"
else
  echo "[autorun-setup] ERROR: autorun.service not found" >&2
  exit 1
fi

# Copy autorun binary
if [[ -f "$SCRIPT_DIR/anthonyware-usb-autorun" ]]; then
  cp "$SCRIPT_DIR/anthonyware-usb-autorun" /usr/local/bin/anthonyware-usb-autorun
  chmod +x /usr/local/bin/anthonyware-usb-autorun
  echo "[autorun-setup] ✓ Binary installed to /usr/local/bin/"
else
  echo "[autorun-setup] ERROR: anthonyware-usb-autorun not found" >&2
  exit 1
fi

# Enable the service
systemctl daemon-reload
systemctl enable anthonyware-usb-autorun.service

echo "[autorun-setup] ✓ Service enabled."
echo
echo "[autorun-setup] ===== INSTALLATION COMPLETE ====="
echo "[autorun-setup]"
echo "[autorun-setup] Autorun is now installed and will run on next boot."
echo "[autorun-setup]"
echo "[autorun-setup] To complete setup:"
echo "[autorun-setup]   1. Reboot the system"
echo "[autorun-setup]   2. On next boot, autorun will check for USB_AUTORUN_ENABLED"
echo "[autorun-setup]   3. If present, installer runs automatically"
echo "[autorun-setup]"
echo "[autorun-setup] To arm autorun on the USB:"
echo "[autorun-setup]   touch $REPO_ROOT/USB_AUTORUN_ENABLED"
echo "[autorun-setup]"
echo "[autorun-setup] To disarm:"
echo "[autorun-setup]   rm -f $REPO_ROOT/USB_AUTORUN_ENABLED"
echo "[autorun-setup]"
