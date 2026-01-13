# IOMMU Checklist

- BIOS: enable SVM / VT-d
- GRUB: amd_iommu=on iommu=pt
- Modules loaded:
  - vfio
  - vfio_pci
  - vfio_virqfd
  - vfio_iommu_type1
- GPU isolated from host
- NVIDIA blacklisted on host
- OVMF firmware selected in VM
- Q35 chipset
- Hugepages optional
- Looking Glass optional
