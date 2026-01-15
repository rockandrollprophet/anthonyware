#!/usr/bin/env bash
set -euo pipefail

# Enable dry-run mode (set DRY_RUN=1 before running to skip destructive operations)
DRY_RUN="${DRY_RUN:-0}"
export DRY_RUN

# Ensure TARGET_USER and TARGET_HOME are set
if [[ -z "${TARGET_USER:-}" ]]; then
  TARGET_USER="${SUDO_USER:-${USER}}"
  export TARGET_USER
fi

if [[ -z "${TARGET_HOME:-}" ]]; then
  TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  export TARGET_HOME
fi

# Repo path for config deployment
if [[ -z "${REPO_PATH:-}" ]]; then
  REPO_PATH="${TARGET_HOME}/anthonyware"
  export REPO_PATH
fi

LOG_DIR="${TARGET_HOME}/anthonyware-logs"
mkdir -p "$LOG_DIR"

SCRIPTS=(
  "00-preflight-checks.sh"
  "01-base-system.sh"
  "02-qt6-runtime.sh"
  "03-hyprland.sh"
  "04-daily-driver.sh"
  "05-dev-tools.sh"
  "06-ai-ml.sh"
  "07-cad-cnc-3dprinting.sh"
  "08-hardware-support.sh"
  "09-security.sh"
  "10-backups.sh"
  "10-webcam-media.sh"
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
  "32-latex-docs.sh"
  "33-cleaner.sh"
  "34-diagnostics.sh"
  "35-fusion360-runtime.sh"
  "36-xwayland-legacy.sh"
  "33-user-configs.sh"
  "35-validation.sh"
  "99-update-everything.sh"
)

echo "=============================================="
echo " Anthonyware OS 1.0 Installer"
echo "=============================================="
echo "Target User:  $TARGET_USER"
echo "Target Home:  $TARGET_HOME"
echo "Log Dir:      $LOG_DIR"
echo "Dry Run:      $DRY_RUN"
echo "Repository:   $REPO_PATH"
echo "=============================================="
echo

for script in "${SCRIPTS[@]}"; do
    if [[ ! -f "$(dirname "$0")/$script" ]]; then
      echo "⚠ SKIP: $script (not found)"
      continue
    fi
    
    echo ">>> Running $script"
    if bash "$(dirname "$0")/$script" 2>&1 | tee "$LOG_DIR/$script.log"; then
      echo ">>> ✓ Completed $script"
    else
      echo ">>> ✗ FAILED: $script (see log for details)"
      # Continue on error to gather diagnostics
    fi
    echo
done

echo "=============================================="
echo " Installation Pipeline Complete"
echo "=============================================="
echo "Check logs: tail -f $LOG_DIR/*.log"
echo "=============================================="