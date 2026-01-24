#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [26] Archive & Compression Tools ==="

${SUDO} pacman -S --noconfirm --needed \
    zip \
    unzip \
    p7zip \
    unrar \
    lrzip \
    lzop \
    xz \
    zstd \
    tar \
    cpio

echo "=== Archive Tools Setup Complete ==="