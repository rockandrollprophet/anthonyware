#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/anthonyware-logs"
mkdir -p "$LOG_DIR"

SCRIPTS=(
  "00-preflight-checks.sh"
  "01-base-system.sh"
  "02-gpu-drivers.sh"
  "03-hyprland.sh"
  "04-daily-driver.sh"
  "05-dev-tools.sh"
  "06-ai-ml.sh"
  "07-cad-cnc-3dprinting.sh"
  "08-hardware-support.sh"
  "09-security.sh"
  "10-backups.sh"
  "11-vfio-windows-vm.sh"
  "12-printing.sh"
  "13-fonts.sh"
  "14-portals.sh"
  "15-power-management.sh"
  "16-firmware.sh"
  "17-steam.sh"
  "18-networking-tools.sh"
  "19-electrical-engineering.sh"
  "20-fpga-toolchain.sh"
  "21-instrumentation.sh"
  "22-homelab-tools.sh"
  "23-terminal-qol.sh"
  "24-cleanup-and-verify.sh"
  "25-color-management.sh"
  "26-archive-tools.sh"
  "27-zram-swap.sh"
  "28-audio-routing.sh"
  "29-misc-utilities.sh"
  "30-finalize.sh"
  "31-wayland-recording.sh"
  "32-xwayland-legacy.sh"
  "33-cleaner.sh"
  "99-update-everything.sh"
)

echo "=== Anthonyware OS Installer ==="
echo "Logs will be saved to: $LOG_DIR"
echo

for script in "${SCRIPTS[@]}"; do
    echo ">>> Running $script"
    bash "$(dirname "$0")/$script" 2>&1 | tee "$LOG_DIR/$script.log"
    echo ">>> Completed $script"
    echo
done

echo "=== Installation Complete ==="