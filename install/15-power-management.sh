#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [15] Power Management ==="

${SUDO} pacman -S --noconfirm --needed \
    tlp \
    tlp-rdw \
    powertop \
    auto-cpufreq \
    thermald

${SUDO} systemctl enable --now tlp
${SUDO} systemctl enable --now thermald

echo "=== Power Management Setup Complete ==="