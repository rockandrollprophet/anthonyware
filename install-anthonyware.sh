#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Anthonyware OS 1.0 — Full System Installer
#
#  This is the master installation script.
#  Run from Arch Linux ISO to fully provision a machine.
#
#  Usage: sudo ./install-anthonyware.sh
#
#  What it does:
#    1. Wipes /dev/nvme0n1
#    2. Creates Btrfs subvolumes
#    3. Installs base Arch Linux
#    4. Chroots and configures system
#    5. Clones Anthonyware repo
#    6. Runs full installation pipeline
#    7. Reboots into configured system
# ============================================================

set +u  # Allow unset variables for initial check
if [[ "${EUID:-}" != "0" ]]; then
  echo "ERROR: This script must be run as root (sudo)." >&2
  exit 1
fi
set -u

# ============================================================
#  CONFIGURATION
# ============================================================

DISK="${DISK:-/dev/nvme0n1}"
HOSTNAME="${HOSTNAME:-anthonyware}"
USERNAME="${USERNAME:-rockandrollprophet}"
TIMEZONE="${TIMEZONE:-America/New_York}"
LOCALE="${LOCALE:-en_US.UTF-8}"
REPO_URL="${REPO_URL:-https://github.com/YOURNAME/anthonyware}"

# Prompt for values if not set
read -rp "Target disk [$DISK]: " INPUT && [[ -n "$INPUT" ]] && DISK="$INPUT"
read -rp "Hostname [$HOSTNAME]: " INPUT && [[ -n "$INPUT" ]] && HOSTNAME="$INPUT"
read -rp "Username [$USERNAME]: " INPUT && [[ -n "$INPUT" ]] && USERNAME="$INPUT"
read -rsp "User password: " PASSWORD && echo
read -rsp "Root password: " ROOT_PASSWORD && echo
read -rp "Repository URL [$REPO_URL]: " INPUT && [[ -n "$INPUT" ]] && REPO_URL="$INPUT"

# ============================================================
#  VERIFICATION
# ============================================================

echo "╔══════════════════════════════════════════════════════╗"
echo "║ Anthonyware OS 1.0 Installer                         ║"
echo "╚══════════════════════════════════════════════════════╝"
echo
echo "Target disk:    $DISK"
echo "Hostname:       $HOSTNAME"
echo "Username:       $USERNAME"
echo "Timezone:       $TIMEZONE"
echo "Locale:         $LOCALE"
echo "Repository:     $REPO_URL"
echo
echo "⚠️  WARNING: This will ERASE $DISK"
echo

read -rp "Type YES to continue: " confirm
if [[ "$confirm" != "YES" ]]; then
  echo "Aborted."
  exit 0
fi

# ============================================================
#  PARTITIONING
# ============================================================

echo
echo "[1/6] Partitioning disk..."

if ! [[ -b "$DISK" ]]; then
  echo "ERROR: Disk $DISK not found." >&2
  exit 1
fi

# Wipe filesystem signatures
wipefs -a "$DISK" 2>/dev/null || true

# Create partition table (GPT)
sgdisk -Z "$DISK" || true
sleep 1

# Create EFI partition (512 MiB)
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" "$DISK"

# Create root partition (remaining space)
sgdisk -n 2:0:0 -t 2:8300 -c 2:"ROOT" "$DISK"

EFI="${DISK}p1"
ROOT="${DISK}p2"

echo "✓ Partitioning complete"
echo "  EFI:  $EFI"
echo "  ROOT: $ROOT"

# ============================================================
#  FORMATTING
# ============================================================

echo
echo "[2/6] Formatting..."

mkfs.fat -F32 "$EFI" >/dev/null 2>&1
mkfs.btrfs -f "$ROOT" >/dev/null 2>&1

echo "✓ Filesystems created"

# ============================================================
#  BTRFS SUBVOLUMES
# ============================================================

echo
echo "[3/6] Creating Btrfs subvolumes..."

mount "$ROOT" /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@snapshots

umount /mnt

echo "✓ Subvolumes created"

# ============================================================
#  MOUNTING
# ============================================================

echo
echo "[4/6] Mounting filesystems..."

# Mount root subvolume
mount -o subvol=@,compress=zstd,relatime "$ROOT" /mnt

# Create mount points
mkdir -p /mnt/{boot,home,var/{log,cache/pacman/pkg},.snapshots}

# Mount other subvolumes
mount -o subvol=@home,compress=zstd,relatime "$ROOT" /mnt/home
mount -o subvol=@log,compress=zstd,relatime "$ROOT" /mnt/var/log
mount -o subvol=@pkg,compress=zstd,relatime "$ROOT" /mnt/var/cache/pacman/pkg
mount -o subvol=@snapshots,compress=zstd,relatime "$ROOT" /mnt/.snapshots

# Mount EFI
mount "$EFI" /mnt/boot

echo "✓ Filesystems mounted"

# ============================================================
#  BASE SYSTEM
# ============================================================

echo
echo "[5/6] Installing base system (this may take several minutes)..."

pacstrap -K /mnt base base-devel linux linux-firmware linux-headers \
  networkmanager sudo git btrfs-progs grub efibootmgr >/dev/null 2>&1

genfstab -U /mnt >> /mnt/etc/fstab

echo "✓ Base system installed"

# ============================================================
#  CHROOT PHASE
# ============================================================

echo
echo "[6/6] Configuring system in chroot..."

arch-chroot /mnt /bin/bash << CHROOT_EOF
set -euo pipefail

# ---- Timezone & Locale ----
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

sed -i "s/#${LOCALE}/${LOCALE}/" /etc/locale.gen
locale-gen

echo "LANG=${LOCALE}" > /etc/locale.conf

# ---- Hostname & Network ----
echo "$HOSTNAME" > /etc/hostname

systemctl enable NetworkManager

# ---- User Management ----
echo "Creating user: $USERNAME"
useradd -m -s /bin/bash "$USERNAME" 2>/dev/null || true
echo "$USERNAME:$PASSWORD" | chpasswd
echo "root:$ROOT_PASSWORD" | chpasswd

# Grant wheel group passwordless sudo
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
usermod -aG wheel,docker,libvirt "$USERNAME"

# ---- Bootloader ----
echo "Installing GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB >/dev/null 2>&1
grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1

# ---- Set up repository ----
echo "Cloning Anthonyware repository..."
REPO_PATH="/home/$USERNAME/anthonyware"
sudo -u "$USERNAME" git clone "$REPO_URL" "\$REPO_PATH" 2>/dev/null || {
  echo "Warning: Failed to clone repo. Check URL and network."
}

# ---- Run installer pipeline ----
if [[ -d "\$REPO_PATH/install" ]]; then
  echo "Running Anthonyware installation pipeline..."
  cd "\$REPO_PATH/install"
  
  export TARGET_USER="$USERNAME"
  export TARGET_HOME="/home/$USERNAME"
  export REPO_PATH="\$REPO_PATH"
  
  bash -c 'sudo TARGET_USER="$TARGET_USER" TARGET_HOME="$TARGET_HOME" REPO_PATH="$REPO_PATH" ./run-all.sh' || true
else
  echo "Warning: install directory not found in cloned repo."
fi

echo "=== Chroot configuration complete ==="

CHROOT_EOF

# ============================================================
#  CLEANUP & REBOOT
# ============================================================

echo
echo "╔══════════════════════════════════════════════════════╗"
echo "║ Installation Complete                               ║"
echo "╚══════════════════════════════════════════════════════╝"
echo
echo "System is ready to boot."
echo
echo "Unmounting filesystems..."
umount -R /mnt >/dev/null 2>&1 || true

echo
echo "Configuration Summary:"
echo "  Hostname:  $HOSTNAME"
echo "  User:      $USERNAME"
echo "  Timezone:  $TIMEZONE"
echo "  Locale:    $LOCALE"
echo
echo "First Boot Steps:"
echo "  1. Reboot: systemctl reboot"
echo "  2. Login with username: $USERNAME"
echo "  3. Run: scripts/first-boot-wizard.sh"
echo "  4. Run: scripts/welcome.sh"
echo
read -rp "Reboot now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  reboot
else
  echo "Ready to reboot when you are. Run: sudo reboot"
fi
