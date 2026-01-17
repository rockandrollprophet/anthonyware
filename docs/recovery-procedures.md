# Recovery Procedures — Anthonyware OS

This document provides step-by-step procedures for recovering from common system failures.

---

## Table of Contents

1. [Boot Failures](#boot-failures)
2. [Kernel Panics](#kernel-panics)
3. [Graphics Driver Issues](#graphics-driver-issues)
4. [NetworkManager Not Starting](#networkmanager-not-starting)
5. [Hyprland Won't Start](#hyprland-wont-start)
6. [Pacman Database Corruption](#pacman-database-corruption)
7. [Full System Restore](#full-system-restore)
8. [Emergency Shell Access](#emergency-shell-access)

---

## Boot Failures

### Symptoms

- System won't boot past GRUB
- Black screen after boot loader
- Stuck at "Loading initramfs"

### Recovery Steps

1. **Boot into Live USB**

   ```bash
   # Download Arch Linux ISO and boot from USB
   ```

2. **Mount Your System**

   ```bash
   # Find your partitions
   lsblk
   
   # Mount root (adjust device names as needed)
   mount -o subvol=@ /dev/nvme0n1p2 /mnt
   mount /dev/nvme0n1p1 /mnt/boot
   mount -o subvol=@home /dev/nvme0n1p2 /mnt/home
   ```

3. **Chroot Into Your System**

   ```bash
   arch-chroot /mnt
   ```

4. **Reinstall Bootloader**

   ```bash
   grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
   grub-mkconfig -o /boot/grub/grub.cfg
   ```

5. **Regenerate Initramfs**

   ```bash
   mkinitcpio -P
   ```

6. **Exit and Reboot**

   ```bash
   exit
   umount -R /mnt
   reboot
   ```

---

## Kernel Panics

### Symptoms (Kernel Panics)

- System crashes with kernel panic message
- Unable to boot into installed system

### Recovery Steps (Kernel Panics)

1. **Boot from Previous Kernel**
   - At GRUB menu, select "Advanced options"
   - Choose previous kernel version (linux-lts or older version)

2. **If That Works, Remove Problematic Kernel**

   ```bash
   # List installed kernels
   pacman -Q | grep linux
   
   # Remove problematic kernel
   sudo pacman -R linux-<version>
   
   # Reinstall stable kernel
   sudo pacman -S linux linux-headers
   ```

3. **Check Kernel Logs**

   ```bash
   journalctl -b -1 -p err
   dmesg | grep -i error
   ```

4. **Regenerate Initramfs**

   ```bash
   sudo mkinitcpio -P
   sudo grub-mkconfig -o /boot/grub/grub.cfg
   ```

---

## Graphics Driver Issues

### NVIDIA Driver Won't Load

1. **Boot to Console (TTY)**
   - Press `Ctrl+Alt+F2` at boot or during graphical glitch
   - Login with your credentials

2. **Check Driver Status**

   ```bash
   lsmod | grep nvidia
   nvidia-smi
   ```

3. **Reinstall NVIDIA Drivers**

   ```bash
   sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
   sudo mkinitcpio -P
   sudo reboot
   ```

4. **Switch to Nouveau (Open Source Driver)**

   ```bash
   # Remove NVIDIA drivers
   sudo pacman -R nvidia nvidia-utils
   
   # Install nouveau
   sudo pacman -S xf86-video-nouveau
   
   # Blacklist nvidia
   echo "blacklist nvidia" | sudo tee /etc/modprobe.d/blacklist-nvidia.conf
   sudo mkinitcpio -P
   sudo reboot
   ```

### AMD Driver Issues

1. **Ensure AMDGPU Module is Loaded**

   ```bash
   lsmod | grep amdgpu
   ```

2. **Reinstall Mesa Drivers**

   ```bash
   sudo pacman -S --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
   sudo reboot
   ```

---

## NetworkManager Not Starting

### Quick Fix

1. **Restart NetworkManager**

   ```bash
   sudo systemctl restart NetworkManager
   ```

2. **Check Service Status**

   ```bash
   systemctl status NetworkManager
   journalctl -u NetworkManager -n 50
   ```

3. **Reinstall NetworkManager**

   ```bash
   sudo pacman -S --noconfirm networkmanager
   sudo systemctl enable --now NetworkManager
   ```

4. **Manual WiFi Connection**

   ```bash
   # Using iwctl
   iwctl
   # [iwctl]# station wlan0 scan
   # [iwctl]# station wlan0 get-networks
   # [iwctl]# station wlan0 connect "SSID"
   # [iwctl]# exit
   ```

5. **Manual Ethernet Configuration**

   ```bash
   # Get interface name
   ip link
   
   # Bring interface up
   sudo ip link set <interface> up
   
   # Get IP via DHCP
   sudo dhcpcd <interface>
   ```

---

## Hyprland Won't Start

### From TTY (Ctrl+Alt+F2)

1. **Check Hyprland Log**

   ```bash
   cat ~/.hyprland.log
   ```

2. **Test Hyprland Manually**

   ```bash
   Hyprland
   ```

3. **Reset Hyprland Config**

   ```bash
   mv ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.backup
   cp ~/anthonyware/configs/hypr/hyprland.conf ~/.config/hypr/
   ```

4. **Check Dependencies**

   ```bash
   # Run troubleshooter
   bash ~/anthonyware/scripts/troubleshoot-hyprland.sh
   ```

5. **Reinstall Hyprland**

   ```bash
   sudo pacman -S --noconfirm hyprland waybar kitty
   ```

6. **Fall Back to X11 Session**

   ```bash
   sudo pacman -S --noconfirm xorg-server plasma-desktop
   sudo systemctl enable sddm
   # Reboot and select Plasma X11 session
   ```

---

## Pacman Database Corruption

### Symptoms (Pacman Database)

- `error: failed to init transaction (unable to lock database)`
- `error: could not open file: No such file or directory`

### Recovery Steps (Pacman Database)

1. **Remove Lock File**

   ```bash
   sudo rm /var/lib/pacman/db.lck
   ```

2. **Synchronize Databases**

   ```bash
   sudo pacman -Syy
   ```

3. **Repair Database**

   ```bash
   sudo pacman-db-upgrade
   sudo pacman -Syu
   ```

4. **Check All Packages**

   ```bash
   sudo pacman -Qk
   ```

5. **Use Repair Tool**

   ```bash
   sudo bash ~/anthonyware/scripts/repair-packages.sh
   ```

---

## Full System Restore

### From Timeshift Snapshot

1. **Boot Live USB**

2. **Install Timeshift on Live Environment**

   ```bash
   sudo pacman -Sy timeshift
   ```

3. **List Available Snapshots**

   ```bash
   sudo timeshift --list
   ```

4. **Restore Snapshot**

   ```bash
   sudo timeshift --restore
   # Select snapshot from menu
   ```

5. **Reboot**

   ```bash
   sudo reboot
   ```

### From Manual Backup

1. **Boot Live USB and Mount System**

   ```bash
   mount -o subvol=@ /dev/nvme0n1p2 /mnt
   mount /dev/nvme0n1p1 /mnt/boot
   ```

2. **Restore from Backup**

   ```bash
   # If backup is on external drive
   mount /dev/sdb1 /media/backup
   
   # Restore (use with caution)
   rsync -aAXHv --delete /media/backup/system/ /mnt/
   ```

3. **Chroot and Reinstall Bootloader**

   ```bash
   arch-chroot /mnt
   grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
   grub-mkconfig -o /boot/grub/grub.cfg
   exit
   ```

4. **Unmount and Reboot**

   ```bash
   umount -R /mnt
   reboot
   ```

---

## Emergency Shell Access

### Boot to Emergency Mode

1. **Edit GRUB Entry at Boot**
   - Press `e` at GRUB menu
   - Add `systemd.unit=emergency.target` to kernel line
   - Press `Ctrl+X` to boot

2. **Enter Root Password**
   - You'll be prompted for root password

3. **Mount Filesystems**

   ```bash
   mount -o remount,rw /
   mount -a
   ```

4. **Fix Issues, Then Exit**

   ```bash
   systemctl default
   ```

### Boot to Single User Mode

1. **Edit GRUB Entry**
   - Add `single` or `systemd.unit=rescue.target` to kernel line

2. **Perform Repairs**

3. **Exit to Normal Boot**

   ```bash
   systemctl default
   ```

---

## Common Troubleshooting Commands

```bash
# Check system logs
journalctl -p err -b
journalctl --since "1 hour ago"

# Check service status
systemctl --failed
systemctl status <service>

# Check disk health
smartctl -a /dev/nvme0n1

# Check filesystem
sudo btrfs check /dev/nvme0n1p2

# Network diagnostics
ip addr
ip route
ping -c 4 8.8.8.8
resolvectl status

# GPU diagnostics
lspci | grep -i vga
lsmod | grep -i nvidia
nvidia-smi  # NVIDIA only

# Audio diagnostics
pactl list sinks
systemctl --user status pipewire
```

---

## Prevention Best Practices

1. **Regular Backups**
   - Run `~/anthonyware/scripts/backup-system.sh` weekly
   - Create Timeshift snapshots before major changes

2. **Before System Updates**
   - Run `~/anthonyware/scripts/pre-update-snapshot.sh`

3. **Keep Recovery USB Handy**
   - Always have a bootable Arch USB ready

4. **Document Custom Changes**
   - Keep notes of system modifications

5. **Test in VM First**
   - Try risky operations in virtual machine first

---

## Emergency Contacts

- **Arch Linux Forums**: <https://bbs.archlinux.org>
- **Arch Linux Wiki**: <https://wiki.archlinux.org>
- **Hyprland Discord**: <https://discord.gg/hyprland>
- **Repository Issues**: <https://github.com/rockandrollprophet/anthonyware/issues>

---

## Quick Reference Card

Save this for emergencies:

```text
BOOT LIVE USB → lsblk
MOUNT: mount -o subvol=@ /dev/nvme0n1p2 /mnt
       mount /dev/nvme0n1p1 /mnt/boot
CHROOT: arch-chroot /mnt
FIX GRUB: grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
          grub-mkconfig -o /boot/grub/grub.cfg
EXIT: exit && umount -R /mnt && reboot
```

Stay calm, you've got this! 🚀
