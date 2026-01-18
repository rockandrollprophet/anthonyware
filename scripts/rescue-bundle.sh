#!/usr/bin/env bash
# rescue-bundle.sh - Export logs and diagnostics for offline troubleshooting

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="${LOG_DIR:-${HOME}/anthonyware-logs}"
BUNDLE_DIR="/tmp/anthonyware-rescue-$(date +%Y%m%d-%H%M%S)"

echo "Creating rescue bundle at $BUNDLE_DIR..."
mkdir -p "$BUNDLE_DIR"

# Collect installation logs
if [[ -d "$LOG_DIR" ]]; then
  echo "Collecting logs..."
  cp -r "$LOG_DIR" "$BUNDLE_DIR/logs" 2>/dev/null || true
fi

# System information
echo "Gathering system information..."
mkdir -p "$BUNDLE_DIR/system"
{
  echo "=== Hostname ==="
  hostname || true
  echo
  
  echo "=== Kernel ==="
  uname -a || true
  echo
  
  echo "=== CPU Info ==="
  lscpu || true
  echo
  
  echo "=== Memory ==="
  free -h || true
  echo
  
  echo "=== Disk Usage ==="
  df -h || true
  echo
  
  echo "=== Block Devices ==="
  lsblk || true
  echo
  
  echo "=== PCI Devices ==="
  lspci || true
  echo
  
  echo "=== USB Devices ==="
  lsusb || true
  echo
  
  echo "=== Network Interfaces ==="
  ip addr || true
  echo
  
  echo "=== Systemd Failed Units ==="
  systemctl --failed || true
  echo
  
  echo "=== Recent Journal Errors ==="
  journalctl -p err -n 100 --no-pager || true
  echo
} > "$BUNDLE_DIR/system/info.txt"

# Package information
echo "Collecting package information..."
mkdir -p "$BUNDLE_DIR/packages"
pacman -Q > "$BUNDLE_DIR/packages/installed.txt" 2>/dev/null || true
pacman -Qe > "$BUNDLE_DIR/packages/explicit.txt" 2>/dev/null || true
pacman -Qdtq > "$BUNDLE_DIR/packages/orphans.txt" 2>/dev/null || true

# Configuration files
echo "Collecting configuration samples..."
mkdir -p "$BUNDLE_DIR/configs"
for conf in /etc/pacman.conf /etc/fstab /etc/default/grub; do
  if [[ -f "$conf" ]]; then
    cp "$conf" "$BUNDLE_DIR/configs/" 2>/dev/null || true
  fi
done

# Checkpoint and metrics if available
if [[ -f "${LOG_DIR}/installation-checkpoint.txt" ]]; then
  cp "${LOG_DIR}/installation-checkpoint.txt" "$BUNDLE_DIR/checkpoint.txt" 2>/dev/null || true
fi

if [[ -d "${LOG_DIR}/metrics" ]]; then
  cp -r "${LOG_DIR}/metrics" "$BUNDLE_DIR/" 2>/dev/null || true
fi

# SBOM if generated
if [[ -d "${LOG_DIR}/repro" ]]; then
  cp -r "${LOG_DIR}/repro" "$BUNDLE_DIR/" 2>/dev/null || true
fi

# Create archive
echo "Creating tarball..."
BUNDLE_ARCHIVE="/tmp/anthonyware-rescue-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$BUNDLE_ARCHIVE" -C "$(dirname "$BUNDLE_DIR")" "$(basename "$BUNDLE_DIR")" 2>/dev/null

# Cleanup temp directory
rm -rf "$BUNDLE_DIR"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Rescue Bundle Created                                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo
echo "Bundle: $BUNDLE_ARCHIVE"
echo "Size: $(du -h "$BUNDLE_ARCHIVE" | cut -f1)"
echo
echo "Transfer this file to another system for offline analysis."
echo "Extract with: tar -xzf $(basename "$BUNDLE_ARCHIVE")"
echo
