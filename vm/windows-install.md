# Windows VM Install Guide

## 1. Create VM in Virt-Manager
- UEFI (OVMF)
- Q35 chipset
- 8–16 cores
- 16–64GB RAM
- 100–500GB disk

## 2. Attach:
- Windows ISO
- VirtIO ISO

## 3. Install VirtIO Drivers
During Windows install:
- Load storage driver
- Load network driver

## 4. GPU Passthrough
Assign:
- NVIDIA GPU
- NVIDIA audio device

## 5. USB Passthrough
Add:
- 3Dconnexion
- Keyboard
- Mouse
- Dongles

## 6. Install NVIDIA Drivers in Windows
