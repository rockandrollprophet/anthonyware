# Anthonyware OS — Install Guide

This guide provides a comprehensive walkthrough for installing Anthonyware OS from an Arch Linux ISO.

---

## Installation Methods

### Method 1: Automated Installer (Recommended)

The automated installer handles partitioning, base system installation, configuration, and the complete Anthonyware pipeline.

#### Steps

1. **Boot Arch Linux ISO**
   - Download from [archlinux.org](https://archlinux.org/download/)
   - Boot in UEFI mode (recommended)

2. **Connect to Internet**

   ```bash
   # WiFi:
   iwctl
   # [iwctl]# device list
   # [iwctl]# station wlan0 scan
   # [iwctl]# station wlan0 get-networks
   # [iwctl]# station wlan0 connect "YOUR_SSID"
   # [iwctl]# exit
   
   # Ethernet usually auto-connects
   ip link
   ```

3. **Install Git**

   ```bash
   pacman -Sy git
   ```

4. **Clone Repository**

   ```bash
   git clone https://github.com/rockandrollprophet/anthonyware /root/anthonyware
   cd /root/anthonyware
   ```

5. **Run Pre-Install Check (Optional)**

   ```bash
   chmod +x pre-install-check.sh
   sudo ./pre-install-check.sh
   ```

6. **Run Automated Installer**

   ```bash
   chmod +x install-anthonyware.sh
   sudo ./install-anthonyware.sh
   ```

7. **Follow Interactive Prompts**

   The installer will prompt you for:

   | Prompt | Default | Description |
   | -------- | --------- | ------------- |
   | **Target disk** | `/dev/nvme0n1` | ⚠️ Will be completely wiped |
   | **Hostname** | `anthonyware` | Computer name on network |
   | **Username** | _(required)_ | Your login username |
   | **User password** | _(required)_ | Password for login and sudo commands |
   | **Root password** | _(required)_ | Root account password |
   | **Repository URL** | `rockandrollprophet/anthonyware` | Git repo to clone |

   **Security Notes:**
   - Passwords require confirmation (entered twice)
   - All passwords must be non-empty
   - User is added to `wheel` group for sudo access
   - Sudo requires password after installation completes

8. **Reboot**

   After installation completes, reboot into your new system:

   ```bash
   systemctl reboot
   ```

9. **First Boot**

   Login with your username and run the first-boot wizard:

   ```bash
   ~/anthonyware/scripts/first-boot-wizard.sh
   ```

---

### Method 2: Manual Installation

For advanced users who want full control over the installation process.

#### 1. Partitioning

**Recommended Layout:**

- EFI: 512MB (FAT32)
- Root: Remaining space (Btrfs)

```bash
# Example for /dev/nvme0n1
sgdisk -Z /dev/nvme0n1
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" /dev/nvme0n1
sgdisk -n 2:0:0 -t 2:8300 -c 2:"ROOT" /dev/nvme0n1

mkfs.fat -F32 /dev/nvme0n1p1
mkfs.btrfs -f /dev/nvme0n1p2
```

#### 2. Btrfs Subvolumes

```bash
mount /dev/nvme0n1p2 /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@snapshots

umount /mnt

# Mount with compression
mount -o subvol=@,compress=zstd,relatime /dev/nvme0n1p2 /mnt
mkdir -p /mnt/{boot,home,var/{log,cache/pacman/pkg},.snapshots}

mount -o subvol=@home,compress=zstd,relatime /dev/nvme0n1p2 /mnt/home
mount -o subvol=@log,compress=zstd,relatime /dev/nvme0n1p2 /mnt/var/log
mount -o subvol=@pkg,compress=zstd,relatime /dev/nvme0n1p2 /mnt/var/cache/pacman/pkg
mount -o subvol=@snapshots,compress=zstd,relatime /dev/nvme0n1p2 /mnt/.snapshots

mount /dev/nvme0n1p1 /mnt/boot
```

#### 3. Base System

```bash
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers \
  networkmanager sudo git btrfs-progs grub efibootmgr

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt
```

#### 4. System Configuration (Inside Chroot)

```bash
# Timezone
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

# Locale
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "anthonyware" > /etc/hostname

# Enable NetworkManager
systemctl enable NetworkManager

# Create user
useradd -m -s /bin/bash your_username
passwd your_username
passwd root

# Add user to wheel group
usermod -aG wheel your_username

# Enable sudo for wheel group
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Install GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

exit
```

#### 5. Reboot

```bash
umount -R /mnt
reboot
```

#### 6. Post-Install (After Reboot)

```bash
# Clone repository
git clone https://github.com/rockandrollprophet/anthonyware ~/anthonyware
cd ~/anthonyware/install

# Run installation pipeline
chmod +x run-all.sh
sudo ./run-all.sh

# Reboot into Hyprland
sudo reboot
```

---

## Post-Installation

### First Boot Wizard

Run the first-boot wizard to validate your installation and finalize configuration:

```bash
~/anthonyware/scripts/first-boot-wizard.sh
```

### System Validation

Check that everything installed correctly:

```bash
cd ~/anthonyware/install
bash 24-cleanup-and-verify.sh
```

### Health Check

```bash
~/anthonyware/scripts/health-dashboard.sh
```

---

## Troubleshooting

### No Internet Connection

```bash
ping archlinux.org

# If WiFi fails, reconnect:
iwctl
# [iwctl]# station wlan0 connect "YOUR_SSID"
```

### Wrong Disk Selected

```bash
lsblk  # List all disks and partitions
fdisk -l  # Detailed disk information
```

### Installation Failed

```bash
# Check logs
tail ~/anthonyware-logs/*.log

# Try again
cd /root/anthonyware
sudo ./install-anthonyware.sh
```

### GRUB Won't Boot

```bash
# Boot into Arch ISO, mount system
mount -o subvol=@ /dev/nvme0n1p2 /mnt
mount /dev/nvme0n1p1 /mnt/boot
arch-chroot /mnt

# Reinstall GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

---

## System Requirements

### Minimum

- **CPU**: x86_64 processor
- **RAM**: 4GB
- **Disk**: 30GB free space
- **Boot**: UEFI (BIOS supported)
- **Network**: Internet connection required

### Recommended

- **CPU**: Quad-core x86_64 with virtualization support
- **RAM**: 8GB or more
- **Disk**: 50GB+ SSD/NVMe
- **GPU**: Dedicated GPU for Hyprland compositing
- **Network**: Stable broadband connection

### Engineering / Graduate Workload (Recommended)

- **CPU**: 6+ cores (Ryzen 5 / Intel i7 or better)
- **RAM**: 32GB or more (for large CAD models, ML workloads, VMs)
- **Disk**: **800-900GB SSD/NVMe for Arch installation**
  - 512MB EFI partition (`/boot`)
  - 800-900GB Arch root partition (`/`)
  - Remainder: Windows VM partition (if VFIO dual-boot desired)
- **GPU**: Dedicated GPU with CUDA support (NVIDIA RTX series recommended for CUDA/AI/ML)
- **Network**: Stable broadband for package downloads, cloud CAD (Onshape, Fusion 360), and remote tools

### Partition Layout Example (Alienware m17 r5 with 1TB drive)

```bash
# Assuming /dev/nvme0n1 (1TB NVMe)
sgdisk -Z /dev/nvme0n1                             # Wipe partition table
sgdisk -n 1:0:+512M -t 1:ef00 /dev/nvme0n1        # EFI: 512MB
sgdisk -n 2:0:+800G -t 2:8300 /dev/nvme0n1        # Arch: 800GB
sgdisk -n 3:0:0 -t 3:8300 /dev/nvme0n1            # Windows VM: remaining (~188GB)
sgdisk -p /dev/nvme0n1                             # Verify
```

**Key Points:**

- Arch root partition requires **30GB minimum** for base system, but **200GB+ strongly recommended** for engineering tools (CAD, AI/ML, scientific computing, IDEs).
- 800-900GB allocation provides room for:
  - Base system: ~40GB
  - Engineering tools: ~150GB
  - User home (projects, datasets, models): ~400-700GB
- Windows VM partition (if using VFIO for SolidWorks/Siemens NX): ~100-200GB recommended

---

## Next Steps

After installation:

1. Read [First Boot Checklist](first-boot-checklist.md)
2. Review [Security Hardening](security-hardening.md)
3. Explore workflow guides in `docs/`
4. Configure apps in `configs/`

Enjoy Anthonyware OS!
