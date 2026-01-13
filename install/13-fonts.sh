#!/usr/bin/env bash
set -euo pipefail

echo "=== [13] Fonts Setup ==="

sudo pacman -S --noconfirm --needed \
    noto-fonts \
    noto-fonts-extra \
    noto-fonts-emoji \
    ttf-dejavu \
    ttf-liberation \
    ttf-jetbrains-mono \
    ttf-fira-code

# Nerd symbols font (for prompts, icons)
sudo pacman -S --noconfirm --needed ttf-nerd-fonts-symbols

# Optional extra Nerd fonts
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        ttf-jetbrains-mono-nerd \
        ttf-firacode-nerd || echo "WARNING: Some Nerd fonts failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install Nerd fonts manually if desired"
fi

echo "=== Fonts Setup Complete ==="