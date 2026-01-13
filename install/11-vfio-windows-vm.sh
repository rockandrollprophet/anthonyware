#!/usr/bin/env bash
set -euo pipefail

echo "=== [11] VFIO / Windows VM Setup ==="

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
    libvirt

# Enable libvirt + networking
sudo systemctl enable --now libvirtd
sudo systemctl enable --now dnsmasq

# Allow user to manage VMs
sudo usermod -aG libvirt "$USER"

# VirtIO drivers ISO (Windows drivers)
sudo pacman -S --noconfirm --needed virtio-win

# Looking Glass client (optional, but included)
yay -S --noconfirm --needed looking-glass-client

# QEMU guest agent for better integration
sudo pacman -S --noconfirm --needed qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent

# SPICE agent for clipboard / resolution support
sudo pacman -S --noconfirm --needed spice-vdagent

echo "=== VFIO / Windows VM Tooling Setup Complete ==="
echo "NOTE: VM XML, GPU/USB passthrough, and IOMMU group tuning are documented in vm/*.md"