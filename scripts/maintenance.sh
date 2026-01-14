#!/usr/bin/env bash
set -euo pipefail

echo "=== Anthonyware Maintenance ==="

orphans=$(pacman -Qtdq || true)
if [ -n "$orphans" ]; then
    read -r -a orphans_array <<< "$orphans"
    sudo pacman -Rns --noconfirm "${orphans_array[@]}" || echo "WARNING: Failed to remove some orphan packages"
else
    echo "No orphan packages to remove"
fi
sudo pacman -Scc --noconfirm
sudo journalctl --vacuum-time=7d

echo "=== Maintenance Complete ==="
