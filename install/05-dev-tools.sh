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

# Docker setup with validation
TARGET_USER="${SUDO_USER:-$USER}"
echo "Setting up Docker for user: $TARGET_USER"

# Enable and start Docker service
if ${SUDO} systemctl enable --now docker; then
  echo "✓ Docker service enabled"
else
  echo "WARNING: Failed to enable Docker service (may need manual setup)"
fi

# Add user to docker group
if ! groups "${TARGET_USER}" | grep -q docker; then
  ${SUDO} usermod -aG docker "$TARGET_USER" || { echo "ERROR: Failed to add user to docker group"; exit 1; }
  echo "✓ User added to docker group"
  echo ""
  echo "⚠ IMPORTANT: Logout and login again to activate docker group membership"
  echo "   Or run: newgrp docker (temporary for current session)"
else
  echo "✓ User already in docker group"
fi

# Rust toolchain
echo "Initializing Rust toolchain..."
rustup default stable || echo "⚠ Rust toolchain setup incomplete - run 'rustup default stable' manually"

# VS Code (AUR) - install yay safely first
if ! command -v yay >/dev/null 2>&1; then
  echo "Installing yay AUR helper first..."
  if ! safe_pacman -S base-devel git; then
    echo "ERROR: Failed to install yay dependencies"
    exit 1
  fi
  
  YAY_DIR="/tmp/yay-install-$$"
  if git clone https://aur.archlinux.org/yay.git "$YAY_DIR" 2>&1; then
    (cd "$YAY_DIR" && makepkg -si --noconfirm) || {
      echo "ERROR: Failed to build yay";
      rm -rf "$YAY_DIR";
      exit 1;
    }
    rm -rf "$YAY_DIR"
  else
    echo "ERROR: Failed to clone yay repository";
    exit 1;
  fi
  
  # Verify installation
  if ! command -v yay >/dev/null 2>&1; then
    echo "ERROR: yay installation failed verification"
    exit 1
  fi
  echo "✓ yay installed successfully"
fi

if command -v yay >/dev/null; then
    echo "Installing VS Code from AUR..."
    yay -S --noconfirm --needed visual-studio-code-bin || echo "WARNING: visual-studio-code-bin failed to install via yay"
else
    echo "NOTICE: 'yay' not available; install visual-studio-code-bin manually if desired"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Development Tools Setup Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠ IMPORTANT NEXT STEPS:"
echo ""
echo "  1. LOGOUT and LOGIN again to activate group memberships"
echo "     (Required for Docker access)"
echo ""
echo "  2. Test Docker access:"
echo "     docker run hello-world"
echo ""
echo "  3. Configure Git:"
echo "     git config --global user.name \"Your Name\""
echo "     git config --global user.email \"you@example.com\""
echo ""
echo "  4. Optional VS Code extensions:"
echo "     code --install-extension rust-lang.rust-analyzer"
echo "     code --install-extension ms-python.python"
echo ""
echo "═══════════════════════════════════════════════════"