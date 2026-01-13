# Anthonyware OS — Install Guide

This guide walks through installing Anthonyware on a fresh Arch Linux system.

---

## 1. Boot Into Arch ISO
- Use Ventoy or dd to write the ISO.
- Boot into UEFI mode.
- Connect to WiFi: `iwctl`
- Update system clock: `timedatectl set-ntp true`

---

## 2. Partitioning (Recommended Layout)
- EFI: 512MB (FAT32)
- Root: Rest of disk (Btrfs)

Example:
mkfs.fat  -F32 /dev/nvme0n1p1
mkfs.btrfs  /dev/nvme0n1p2

---

## 3. Btrfs Subvolumes
mount /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt

Mount:
mount -o subvol=@,compress=zstd /dev/nvme0n1p2 /mnt
mkdir /mnt/{boot,home,.snapshots}
mount -o subvol=@home /dev/nvme0n1p2 /mnt/home
mount -o subvol=@snapshots /dev/nvme0n1p2 /mnt/.snapshots
mount /dev/nvme0n1p1 /mnt/boot

---

## 4. Install Base System
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

---

## 5. Inside Chroot
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

Enable locale:
en_US.UTF-8 UTF-8

Install GRUB:
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

---

## 6. Reboot Into Arch
Login as your user.

---

## 7. Clone Anthonyware Repo
git clone https://github.com/<yourname>/anthonyware-arch
cd anthonyware-arch/install

---

## 8. Run Installer
chmod +x run-all.sh
./run-all.sh

---

## 9. Reboot Into Hyprland
Enjoy Anthonyware.
