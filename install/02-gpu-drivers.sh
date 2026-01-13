#!/usr/bin/env bash
set -euo pipefail

echo "=== [02] GPU Drivers Setup ==="

# AMD GPU (host)
sudo pacman -S --noconfirm --needed \
    mesa \
    mesa-utils \
    vulkan-radeon \
    libva-mesa-driver \
    mesa-vdpau

# NVIDIA GPU (passthrough + CUDA)
sudo pacman -S --noconfirm --needed \
    nvidia \
    nvidia-utils \
    nvidia-settings \
    opencl-nvidia \
    cuda \
    cudnn

# VFIO kernel modules
sudo tee /etc/modules-load.d/vfio.conf >/dev/null <<EOF
vfio
vfio_pci
vfio_virqfd
vfio_iommu_type1
EOF

# Blacklist NVIDIA on host (for passthrough)
sudo tee /etc/modprobe.d/blacklist-nvidia.conf >/dev/null <<EOF
blacklist nvidia
blacklist nvidia_uvm
blacklist nvidia_modeset
blacklist nvidia_drm
EOF

# Enable IOMMU
sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="amd_iommu=on iommu=pt /' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "=== GPU Drivers Setup Complete ==="