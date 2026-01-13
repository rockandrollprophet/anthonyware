#!/usr/bin/env bash
set -euo pipefail

echo "=== [05] Development Tools ==="

# Core dev tools
sudo pacman -S --noconfirm --needed \
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
sudo pacman -S --noconfirm --needed \
    zoxide \
    atuin \
    broot \
    yazi

# Docker setup
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

# Rust toolchain
rustup default stable

# VS Code (AUR)
yay -S --noconfirm --needed visual-studio-code-bin

echo "=== Development Tools Setup Complete ==="