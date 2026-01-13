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
yay -S --noconfirm --needed \
    ttf-jetbrains-mono-nerd \
    ttf-firacode-nerd

echo "=== Fonts Setup Complete ==="