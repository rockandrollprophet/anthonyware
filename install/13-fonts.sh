#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [13] Fonts Setup ==="

${SUDO} pacman -S --noconfirm --needed \
    noto-fonts \
    noto-fonts-extra \
    noto-fonts-emoji \
    noto-fonts-cjk \
    ttf-dejavu \
    ttf-liberation \
    ttf-jetbrains-mono \
    ttf-fira-code \
    ttf-nerd-fonts-symbols \
    papirus-icon-theme

# Optional extra Nerd fonts
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        ttf-jetbrains-mono-nerd \
        ttf-firacode-nerd || echo "WARNING: Some Nerd fonts failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install Nerd fonts manually if desired"
fi

echo "=== Fonts Setup Complete ==="