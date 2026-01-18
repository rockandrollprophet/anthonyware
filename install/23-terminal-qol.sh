#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [23] Terminal Quality-of-Life Tools ==="

${SUDO} pacman -S --noconfirm --needed \
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
echo 'eval "$(starship init zsh)"' >> ~/.zshrc

echo "=== Terminal QoL Setup Complete ==="