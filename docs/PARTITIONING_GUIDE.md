# Anthonyware Disk Partitioning Guide

## Quick Answer: Why NOT Separate /home?

**TL;DR**: For Anthonyware, `/` and `/home` are on the same partition because:

1. Both are accessed together (OS + user data = single unit)
2. Engineering workloads use ~40GB OS + 400-700GB user data → combined single partition is simpler
3. Snapshots/backups easier on single partition
4. No traditional reasons apply (no separate OS upgrades in Arch rolling release)

---

## Partition Layout (Recommended for 1TB Drive)

```bash
/dev/nvme0n1
├── Part 1 (512 MB)    → EFI (/boot)              [ef00]
├── Part 2 (800 GB)    → Arch (/ + /home)         [8300]
└── Part 3 (188 GB)    → Windows VM (optional)    [8300]
```

**Inside Part 2 (`/`):**

- `/`           : OS, packages, config (40-50 GB used)
- `/home`       : User home, projects, datasets (400-700 GB)
- `/opt`        : Optional custom builds
- `/var/cache`  : Package cache
- Free space    : Snapshots, growth

**Inside Part 3 (optional):**

- VFIO Windows disk image (for SolidWorks/Siemens NX GPU passthrough)

---

## Why This Layout?

### Single Arch Partition (not separate /home)

| Aspect | Traditional | Anthonyware |
| --- | --- | --- |
| Backup | Mount both, backup both separately | Mount once, backup once |
| Snapshots | Need to snapshot both | Single snapshot includes everything |
| Fragmentation | Risk when / and /home fill differently | No risk (single allocation) |
| OS upgrade | Easier to preserve /home on re-install | Not needed (rolling release) |
| Space efficiency | Rigid: / too small, /home wastes space | Flexible: single partition resizes with content |

**Anthonyware benefit**: You can snapshot the entire disk state at once (`system-snapshot.sh`), restore it at once. No partial restore issues.

### EFI Partition (512 MB)

- UEFI firmware requirement: separate FAT32 partition for bootloader
- 512 MB standard (UEFI spec supports 100 MB, but 512 MB is safe)
- Contains: GRUB, kernel, UEFI variables

### Windows VM Partition (optional)

- VFIO enables GPU passthrough: Linux runs Arch, Windows VM runs SolidWorks
- Partition 3 holds the QEMU virtual disk image (~188 GB for engineering workloads)
- Can skip if no Windows CAD tools needed

---

## Disk Size Adaptation

This script (`scripts/smart-partition.sh`) auto-adapts to your disk size:

### 100-200 GB: Arch-only (minimal)

```bash
EFI:  512 MB
Arch: Remaining (~100-200 GB)
VM:   None
```

Use case: Portable install, tight space

### 200-500 GB: Balanced

```bash
EFI:  512 MB
Arch: 250 GB
VM:   Remaining (~250 GB)
```

Use case: Dual-boot Arch + Windows

### 500-800 GB: Large Arch, VM

```bash
EFI:  512 MB
Arch: 400 GB
VM:   Remaining (~400 GB)
```

Use case: Engineering + large Windows VM

### 800 GB - 1 TB: Engineering workstation (target)

```bash
EFI:      512 MB
Arch:     800 GB     ← Engineering tool target
Windows:  188 GB     ← Optional VFIO
```

Use case: Anthonyware full, Alienware m17 r5

### 1 TB+: Maximum engineering + VM

```bash
EFI:      512 MB
Arch:     800 GB     ← Full engineering
Windows:  Remaining  ← Large VM (200+ GB)
```

Use case: Maximum capability

---

## Using `smart-partition.sh`

### Step 1: Boot Arch ISO

```bash
# On the target machine, boot the Arch ISO
# Ensure internet connection, then:

mkdir -p ~/anthonyware
cd ~/anthonyware
git clone https://github.com/rockandrollprophet/anthonyware .
```

### Step 2: Run the partitioner

```bash
sudo bash scripts/smart-partition.sh
```

The script will:

1. Detect available disks (NVMe, SATA, USB)
2. Analyze disk size
3. Recommend partition layout
4. Generate sgdisk commands
5. Prompt you to confirm before executing

### Step 3: Execute partitioning

```bash
# Copy the suggested sgdisk commands:
sgdisk -Z /dev/nvme0n1                             # Wipe partition table
sgdisk -n 1:0:+512M -t 1:ef00 /dev/nvme0n1        # EFI: 512MB
sgdisk -n 2:0:+800G -t 2:8300 /dev/nvme0n1        # Arch: 800GB
sgdisk -n 3:0:0 -t 3:8300 /dev/nvme0n1            # Windows VM: remaining
sgdisk -p /dev/nvme0n1                             # Verify
```

### Step 4: Format and mount

```bash
mkfs.fat -F 32 -n EFI /dev/nvme0n1p1               # EFI (FAT32)
mkfs.ext4 -L Arch /dev/nvme0n1p2            # Arch (ext4)
```

### Step 5: Continue with Anthonyware installer

```bash
# Mount
mount /dev/nvme0n1p2 /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

# Run installer
cd /mnt
bash install/run-all.sh
```

---

## ext4 vs Btrfs vs ZFS

### ext4 (Anthonyware default)

**Pros:**

- Stable, mature, battle-tested since 2008
- Fast (especially on NVMe)
- Compatible with every tool (backup, VFIO, LVM)
- Simplest recovery if corrupted

**Cons:**

- No native snapshots (we use `system-snapshot.sh` instead)
- Slower fsck on very large partitions

**Use case:** Engineering workloads, VFIO. ✓

### Btrfs

**Pros:**

- Native snapshots, copy-on-write (CoW)
- Dynamic resizing

**Cons:**

- Slower than ext4
- Subvolume complexity for VFIO
- Less stable with GPU passthrough (occasional reports of corruption under heavy load)

**Use case:** Workstations without VFIO. Maybe.

### ZFS

**Pros:**

- Snapshots, compression, RAID

**Cons:**

- Huge memory overhead (8GB+)
- Kernel module licensing concerns
- Not available in Arch default kernel

**Use case:** Not recommended for Anthonyware.

---

## Partition Management Post-Install

### Monitor disk usage

```bash
df -h /
du -sh ~/
```

### Create snapshots before major work

```bash
sudo bash scripts/system-snapshot.sh create pre-update
```

### Restore from snapshot

```bash
sudo bash scripts/system-snapshot.sh restore pre-update
```

### Resize partition (if needed later)

```bash
# Check free space on disk
fdisk -l /dev/nvme0n1

# Resize ext4 partition (online, no reboot)
sudo resize2fs /dev/nvme0n1p2
```

---

## Advanced: LVM (Optional)

Want flexible resizing without repartitioning? Use LVM:

```bash
# Create LVM physical volume
sudo pvcreate /dev/nvme0n1p2

# Create volume group
sudo vgcreate vg-arch /dev/nvme0n1p2

# Create logical volumes
sudo lvcreate -L 800G -n lv-arch vg-arch

# Format
sudo mkfs.ext4 /dev/vg-arch/lv-arch
```

Advantages:
- Resize on-the-fly without repartitioning
- Create snapshots easily

Disadvantages:
- Extra layer of complexity
- Snapshot recovery more complex

---

## Dual-Boot: Windows + Arch on Same Drive

Layout for dual-boot (GRUB chains to Windows bootloader):

```bash
Part 1: EFI       (512 MB shared)
Part 2: Arch      (400 GB, ext4)
Part 3: Windows   (600 GB, NTFS)
```

Not recommended for Anthonyware (too tight). Better: Use VFIO VM instead.

---

## Installation from USB

Use `run-from-usb.sh` to boot Anthonyware entirely from USB:

```bash
# On a 64GB USB stick:
sudo bash run-from-usb.sh /dev/sdb

# Boot from USB, install to internal NVMe
# (Arch stays on internal drive after install)
```

---

## Troubleshooting

### "sgdisk: command not found"

```bash
sudo pacman -S gptfdisk
```

### "Cannot partition; disk is in use"

```bash
# Unmount all partitions
sudo umount /mnt -R

# Boot from fresh ISO if needed
```

### "Partition table corrupted"

```bash
# Back up GPT
sudo sgdisk -b /tmp/gpt-backup.bin /dev/nvme0n1

# Rebuild from backup
sudo sgdisk -l /tmp/gpt-backup.bin /dev/nvme0n1
```

### "Anthonyware installer fails to mount"

```bash
# Check filesystem type
sudo blkid /dev/nvme0n1p2

# Ensure /mnt is clean
sudo umount /mnt -R
sudo mkdir -p /mnt/boot
```

---

## References & Further Reading

| Topic | Resource |
| --- | --- |
| GPT partitioning | [Arch Wiki: gdisk](https://wiki.archlinux.org/index.php/Gdisk) |
| ext4 filesystem | [Kernel docs](https://www.kernel.org/doc/html/latest/filesystems/ext4/) |
| VFIO GPU passthrough | [Arch Wiki: PCI passthrough](https://wiki.archlinux.org/index.php/PCI_passthrough) |
| LVM setup | [Arch Wiki: LVM](https://wiki.archlinux.org/index.php/LVM) |
| Snapshots | [system-snapshot.sh](../scripts/system-snapshot.sh) |
