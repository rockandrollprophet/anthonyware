#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [16] Firmware & Microcode ==="

${SUDO} pacman -S --noconfirm --needed \
    fwupd \
    linux-firmware \
    amd-ucode

${SUDO} systemctl enable --now fwupd.service

echo "=== Firmware Setup Complete ==="