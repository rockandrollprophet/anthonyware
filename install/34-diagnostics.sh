#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

# 34-diagnostics.sh
# Install kernel/storage diagnostics tools: smartmontools, nvme-cli, memtest86+, kdump.

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "This script must be run as root (via ${SUDO} from run-all.sh)." >&2
  exit 1
fi

TARGET_USER="${TARGET_USER:-${SUDO_USER:-}}"
if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
  echo "ERROR: TARGET_USER is not set or is root. Run via run-all.sh, not as pure root." >&2
  exit 1
fi

echo "[34-diagnostics] Installing kernel/storage diagnostics tools..."

pacman --noconfirm --needed -S \
  smartmontools \
  nvme-cli \
  memtest86+ \
  kdump

echo "[34-diagnostics] Diagnostics tools installed."

echo "[34-diagnostics] You can now:"
echo "  - Check disks: ${SUDO} smartctl -a /dev/nvme0n1"
echo "  - Check NVMe health: ${SUDO} nvme smart-log /dev/nvme0n1"
echo "  - Run memtest86+ from the bootloader (if integrated)."
