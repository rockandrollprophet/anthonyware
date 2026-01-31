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
    thermald \
    powertop \
    power-profiles-daemon \
    upower \
    acpi \
    acpid \
    lm_sensors \
    cpupower \
    tlpui

# Only install bolt if Thunderbolt hardware is present
if lsusb | grep -qi thunderbolt; then
    ${SUDO} pacman -S --noconfirm --needed bolt
fi

${SUDO} systemctl enable --now tlp
${SUDO} systemctl enable --now thermald
${SUDO} systemctl enable --now acpid

echo "=== Power Management Setup Complete ==="