#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [29] Misc Utilities ==="

${SUDO} pacman -S --noconfirm --needed \
    jq \
    yq \
    tree \
    wget \
    curl \
    rsync \
    fzf \
    ripgrep \
    fd \
    bat \
    eza \
    tldr \
    neofetch \
    btop \
    htop \
    filelight \
    ncdu \
    duf

echo "=== Misc Utilities Setup Complete ==="