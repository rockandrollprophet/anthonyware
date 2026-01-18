#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [05] Development Tools ==="

# Core dev tools
${SUDO} pacman -S --noconfirm --needed \
    base-devel \
    git \
    git-delta \
    openssh \
    cmake \
    ninja \
    make \
    gcc \
    clang \
    gdb \
    valgrind \
    python \
    python-pip \
    python-virtualenv \
    nodejs \
    npm \
    go \
    rustup \
    jdk-openjdk \
    docker \
    docker-compose \
    jq \
    ripgrep \
    fd \
    bat \
    eza \
    fzf \
    tldr \
    ncdu \
    duf \
    zsh \
    starship \
    neovim \
    kate

# Terminal QoL
${SUDO} pacman -S --noconfirm --needed \
    zoxide \
    atuin \
    broot \
    yazi

# Docker setup
TARGET_USER="${SUDO_USER:-$USER}"
${SUDO} systemctl enable --now docker
${SUDO} usermod -aG docker "$TARGET_USER"

# Rust toolchain
rustup default stable

# VS Code (AUR)
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed visual-studio-code-bin || echo "WARNING: visual-studio-code-bin failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install visual-studio-code-bin manually if desired"
fi

echo "=== Development Tools Setup Complete ==="