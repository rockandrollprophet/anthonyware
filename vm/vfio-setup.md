# VFIO Setup Guide

## 1. Enable IOMMU
GRUB:
amd_iommu=on iommu=pt

## 2. Identify GPU
lspci -nn | grep -i nvidia

## 3. Bind GPU to VFIO
Add IDs to:
/etc/modprobe.d/vfio.conf

## 4. Blacklist NVIDIA on Host
blacklist nvidia
blacklist nvidia_drm

## 5. Regenerate GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

## 6. Reboot
