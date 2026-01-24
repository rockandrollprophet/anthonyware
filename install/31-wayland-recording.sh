#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [31] Wayland Screen Recording ==="

${SUDO} pacman -S --noconfirm --needed \
    wf-recorder \
    obs-studio \
    obs-vkcapture

echo "=== Wayland Recording Setup Complete ==="