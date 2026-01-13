#!/usr/bin/env bash
set -euo pipefail

echo "=== [11] VFIO / Windows VM Setup ==="

TARGET_USER="${SUDO_USER:-$USER}"

# Core virtualization stack
sudo pacman -S --noconfirm --needed \
    qemu-full \
    virt-manager \
    virt-viewer \
    dnsmasq \
    bridge-utils \
    openbsd-netcat \
    iptables-nft \
    edk2-ovmf \
    swtpm \
    libvirt || { echo "ERROR: Failed to install virtualization packages"; exit 1; }

# Enable libvirt + networking
sudo systemctl enable --now libvirtd
sudo systemctl enable --now dnsmasq

# Allow user to manage VMs
sudo usermod -aG libvirt "$TARGET_USER"

# VirtIO drivers ISO (Windows drivers)
sudo pacman -S --noconfirm --needed virtio-win || echo "WARNING: virtio-win install failed"

# Looking Glass client (optional, but included)
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed looking-glass-client || echo "WARNING: looking-glass-client build failed"
else
    echo "NOTICE: 'yay' not found; install looking-glass-client manually if needed"
fi

# QEMU guest agent for better integration
sudo pacman -S --noconfirm --needed qemu-guest-agent || echo "WARNING: qemu-guest-agent install failed"
sudo systemctl enable --now qemu-guest-agent

# SPICE agent for clipboard / resolution support
sudo pacman -S --noconfirm --needed spice-vdagent || echo "WARNING: spice-vdagent install failed"

echo "=== VFIO / Windows VM Tooling Setup Complete ==="
echo "NOTE: VM XML, GPU/USB passthrough, and IOMMU group tuning are documented in vm/*.md"