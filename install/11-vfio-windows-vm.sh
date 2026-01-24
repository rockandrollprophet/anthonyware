#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [11] VFIO / Windows VM Setup ==="

TARGET_USER="${SUDO_USER:-$USER}"

# Fix iptables conflict (iptables-nft replaces iptables)
if pacman -Q iptables &>/dev/null && ! pacman -Q iptables-nft &>/dev/null; then
    echo "Replacing iptables with iptables-nft..."
    ${SUDO} pacman -Rdd --noconfirm iptables || true
fi

# Core virtualization stack
${SUDO} pacman -S --noconfirm --needed \
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
${SUDO} systemctl enable --now libvirtd
${SUDO} systemctl enable --now dnsmasq

# Allow user to manage VMs
${SUDO} usermod -aG libvirt "$TARGET_USER"

# VirtIO drivers ISO (Windows drivers)
${SUDO} pacman -S --noconfirm --needed virtio-win || echo "WARNING: virtio-win install failed"

# Looking Glass client (optional, but included)
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed looking-glass-client || echo "WARNING: looking-glass-client build failed"
else
    echo "NOTICE: 'yay' not found; install looking-glass-client manually if needed"
fi

# QEMU guest agent for better integration
${SUDO} pacman -S --noconfirm --needed qemu-guest-agent || echo "WARNING: qemu-guest-agent install failed"
${SUDO} systemctl enable --now qemu-guest-agent

# SPICE agent for clipboard / resolution support
${SUDO} pacman -S --noconfirm --needed spice-vdagent || echo "WARNING: spice-vdagent install failed"

echo "=== VFIO / Windows VM Tooling Setup Complete ==="
echo "NOTE: VM XML, GPU/USB passthrough, and IOMMU group tuning are documented in vm/*.md"