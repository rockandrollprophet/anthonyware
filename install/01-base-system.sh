#!/usr/bin/env bash
set -euo pipefail

echo "=== [01] Base System Setup ==="

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

# Update system
${SUDO} pacman -Syu --noconfirm

# Enable parallel downloads + color
${SUDO} sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
${SUDO} sed -i 's/^#Color/Color/' /etc/pacman.conf

# Install core packages
${SUDO} pacman -S --noconfirm --needed \
    base-devel \
    git \
    git-lfs \
    curl \
    wget \
    unzip \
    zip \
    tar \
    reflector \
    linux-headers \
    linux-firmware \
    amd-ucode \
    intel-ucode \
    networkmanager \
    network-manager-applet \
    plasma-nm \
    xdg-user-dirs \
    xdg-utils \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    pacman-contrib \
    pkgfile \
    expac \
    pacutils \
    arch-install-scripts \
    archiso \
    htop \
    btop \
    iotop \
    nethogs \
    lsof \
    strace \
    ltrace \
    gdb \
    valgrind \
    perf \
    fzf \
    ripgrep \
    fd \
    bat \
    jq \
    yq \
    bzip2 \
    xz \
    p7zip \
    cmake \
    meson \
    ninja \
    make \
    pkg-config \
    fastfetch \
    inxi \
    zsh \
    bash-completion \
    nmap \
    netcat \
    socat \
    iftop \
    docker \
    docker-compose \
    podman \
    btrfs-progs \
    xfsprogs \
    e2fsprogs \
    dosfstools \
    ntfs-3g \
    exfatprogs \
    usbutils \
    lm_sensors \
    mesa \
    vulkan-tools \
    glfw-wayland

# Enable NetworkManager
${SUDO} systemctl enable --now NetworkManager

# Generate user directories
xdg-user-dirs-update

# Install yay (AUR helper)
if ! command -v yay >/dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay || exit 1
    makepkg -si --noconfirm
    cd - || exit 1
fi

# Update pkgfile database
${SUDO} pkgfile --update

# Install AUR tools and utilities
yay -S --noconfirm --needed \
    paru \
    zoom \
    visual-studio-code-bin \
    lazygit \
    gh \
    topgrade \
    ccache \
    direnv \
    asdf-vm \
    tmux \
    ripgrep-all \
    sd \
    procs \
    hyperfine \
    yamllint \
    prettier \
    shellcheck \
    shfmt \
    nushell \
    watchman

# Optimize mirrors
${SUDO} reflector --country "United States" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

echo "=== Base System Setup Complete ==="