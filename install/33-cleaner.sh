#!/usr/bin/env bash
set -euo pipefail

echo "=== [33] System Cleaner ==="

# Remove orphan packages
orphans=$(pacman -Qtdq || true)
if [ -n "$orphans" ]; then
    sudo pacman -Rns --noconfirm $orphans
fi

# Clean package cache
sudo pacman -Scc --noconfirm

echo "=== System Cleanup Complete ==="