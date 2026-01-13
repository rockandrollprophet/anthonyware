#!/usr/bin/env bash
set -euo pipefail

echo "=== [29] Misc Utilities ==="

sudo pacman -S --noconfirm --needed \
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