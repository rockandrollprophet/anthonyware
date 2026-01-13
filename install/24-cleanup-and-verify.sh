#!/usr/bin/env bash
set -euo pipefail

echo "=== [24] Cleanup & Verification ==="

# Clean orphan packages
orphans=$(pacman -Qtdq || true)
if [ -n "$orphans" ]; then
    read -r -a orphans_array <<< "$orphans"
    sudo pacman -Rns --noconfirm "${orphans_array[@]}" || echo "WARNING: failed to remove some orphans"
else
    echo "No orphan packages to remove"
fi

# Update system one last time
sudo pacman -Syu --noconfirm

# Verify GPU
echo "GPU Info:"
lspci | grep -E "VGA|3D"

# Verify virtualization
echo "Virtualization Extensions:"
grep -E --color=never '(vmx|svm)' /proc/cpuinfo | head

# Verify Wayland
echo "Wayland session check:"
echo "$XDG_SESSION_TYPE"

echo "=== Cleanup & Verification Complete ==="