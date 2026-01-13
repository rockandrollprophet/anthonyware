#!/usr/bin/env bash
set -euo pipefail

echo "=== [26] Archive & Compression Tools ==="

sudo pacman -S --noconfirm --needed \
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