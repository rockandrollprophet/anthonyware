#!/usr/bin/env bash
set -euo pipefail

echo "=== [33] System Cleaner ==="

# Remove orphan packages
orphans=$(pacman -Qtdq || true)
if [ -n "$orphans" ]; then
    read -r -a orphans_array <<< "$orphans"
    sudo pacman -Rns --noconfirm "${orphans_array[@]}" || echo "WARNING: Failed to remove some orphan packages"
else
    echo "No orphan packages to remove"
fi

# Clean package cache
sudo pacman -Scc --noconfirm

echo "=== System Cleanup Complete ==="