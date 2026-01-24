# Anthonyware OS Installation Instructions

## Prerequisites

- Bootable USB with:
  - Arch Linux ISO (2025.12.01 or newer)
  - Anthonyware repository copied to USB
- Target machine with:
  - UEFI firmware
  - At least 50GB storage
  - Internet connection

## Installation Steps

### 1. Boot from Arch ISO

Boot the target machine from the Arch ISO USB.

### 2. Connect to Network

**For WiFi:**

```bash
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "Your-SSID"
# Enter password when prompted
exit
```

**For Ethernet:**
Connection should be automatic.

**Verify:**

```bash
ping -c 3 archlinux.org
```

### 3. Locate Anthonyware Repository

Navigate to where your repository is located on the USB:

```bash
lsblk  # Find your USB device
mkdir -p /mnt/usb
mount /dev/sdX1 /mnt/usb  # Replace sdX1 with your USB partition
cd /mnt/usb/anthonyware
```

### 4. Run Base System Installer

**IMPORTANT**: This installer will:

- **WIPE THE ENTIRE TARGET DISK** (default: /dev/nvme0n1)
- Create EFI + Btrfs partitions with subvolumes
- Install base Arch Linux
- Install GRUB bootloader
- Create hostname (default: anthonyware)
- Set timezone (default: America/New_York)
- Set locale (default: en_US.UTF-8)
- Clone repository to /root/anthonyware-setup/

**This installer does NOT create user accounts or set passwords.**

```bash
# Run the base system installer
bash install-anthonyware.sh
```

When prompted:

- **Target disk**: Confirm or change (e.g., /dev/sda, /dev/nvme0n1)  
  ⚠️  **THIS DISK WILL BE COMPLETELY ERASED**
- **Hostname**: Enter desired hostname or press Enter for default
- **Timezone**: Press Enter for default or specify (e.g., Europe/London)
- **Locale**: Press Enter for default or specify (e.g., en_GB.UTF-8)

The installer will complete in ~5-10 minutes and install the base Arch system with bootloader.

### 5. First Boot - Manual User Setup

After installation completes, remove the USB and reboot. You'll see a text login prompt with no user account yet.

**Press Ctrl+Alt+F2** to get to a root shell (no password needed initially).

Run the user creation script:

```bash
cd /root/anthonyware-setup/anthonyware/install
bash 00-create-user.sh
```

This script will:

1. Prompt for username
2. Create user account
3. Set user password
4. Set root password  
5. Add user to wheel, docker, libvirt groups
6. Configure sudo access

### 6. Run Installation Pipeline

After creating your user account, login as your user and run the full installation pipeline:

```bash
# Login as your new user
# Then run:
cd /root/anthonyware-setup/anthonyware/install
sudo CONFIRM_INSTALL=YES \
     TARGET_USER="YOUR_USERNAME" \
     TARGET_HOME="/home/YOUR_USERNAME" \
     REPO_PATH="/root/anthonyware-setup/anthonyware" \
     bash run-all.sh
```

The pipeline will run for ~45-60 minutes and install:

- All 260+ packages across 44 installation scripts
- Hyprland desktop environment
- SDDM display manager (auto-enabled)
- GPU drivers
- All configured services

### 7. Reboot into Graphical Environment

```bash
sudo reboot
```

You should now see the SDDM graphical login screen. Login with your username and password, select **Hyprland** as the session type.

## Post-Installation

### First Login Checklist

1. **Verify network connection:**

   ```bash
   nmcli device status
   nmcli connection show
   ```

2. **Update system:**

   ```bash
   sudo pacman -Syu
   ```

3. **Check services:**

   ```bash
   systemctl --failed
   systemctl status sddm
   systemctl status NetworkManager
   ```

4. **Verify GPU drivers:**

   ```bash
   lspci -k | grep -A3 -E "VGA|3D"
   ```

### Troubleshooting

**If SDDM doesn't start:**

```bash
sudo systemctl status sddm
sudo journalctl -u sddm -b
# Check for missing Qt6 libraries or configuration errors
```

**If Hyprland session is missing:**

```bash
ls /usr/share/wayland-sessions/
# Should show hyprland.desktop
```

**If sudo doesn't work:**

```bash
# Login as root and check:
cat /etc/sudoers.d/10-wheel
groups YOUR_USERNAME
# Verify user is in wheel group
```

**If WiFi doesn't work:**

```bash
sudo systemctl start NetworkManager
nmcli device wifi list
nmcli device wifi connect "SSID" password "PASSWORD"
```

## Configuration

User configs are located in:

- `~/.config/hypr/` - Hyprland window manager
- `~/.config/waybar/` - Status bar
- `~/.config/kitty/` - Terminal emulator
- `~/.config/wofi/` - Application launcher
- `~/.config/mako/` - Notification daemon

System configs are in the repository at `configs/`.

## Recovery

If installation fails partway through:

1. **Boot back to Arch ISO**
2. **Mount the installed system:**

   ```bash
   mount -o subvol=@ /dev/nvme0n1p2 /mnt
   mount /dev/nvme0n1p1 /mnt/boot
   arch-chroot /mnt
   ```

3. **Create user if not done yet:**

   ```bash
   cd /root/anthonyware-setup/anthonyware/install
   bash 00-create-user.sh
   ```

4. **Resume from failed script:**

   ```bash
   su - YOUR_USERNAME
   cd /root/anthonyware-setup/anthonyware/install
   sudo CONFIRM_INSTALL=YES \
        TARGET_USER="YOUR_USERNAME" \
        TARGET_HOME="/home/YOUR_USERNAME" \
        REPO_PATH="/root/anthonyware-setup/anthonyware" \
        bash run-all.sh
   ```

## Support

For issues, check:

- Installation logs: `~/anthonyware-logs/`
- System journal: `journalctl -b`
- Package cache: `/var/cache/pacman/pkg/`

See `docs/` directory for detailed workflow guides.
