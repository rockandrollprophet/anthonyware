#!/usr/bin/env bash
set -euo pipefail

echo "=== [23] Terminal Quality-of-Life Tools ==="

sudo pacman -S --noconfirm --needed \
    zoxide \
    atuin \
    broot \
    yazi \
    starship \
    fzf \
    ripgrep \
    fd \
    bat \
    eza \
    tldr

# Enable Atuin sync
atuin init zsh >> ~/.zshrc

# Enable Starship prompt
# Intentionally append the literal eval string — do not expand at write-time
# shellcheck disable=SC2016
echo 'eval "$(starship init zsh)"' >> ~/.zshrc

echo "=== Terminal QoL Setup Complete ==="