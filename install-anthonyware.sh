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

# Trap errors and cleanup
trap 'error_handler $? $LINENO' ERR
trap cleanup EXIT INT TERM

cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    echo
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║ Installation Failed                                  ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo
    echo "The system may be in an inconsistent state."
    echo "Check the error messages above for details."
    echo
    # Unmount if mounted
    if mountpoint -q /mnt 2>/dev/null; then
      echo "Attempting to unmount filesystems..."
      umount -R /mnt 2>/dev/null || true
    fi
  fi
}

error_handler() {
  local exit_code=$1
  local line_number=$2
  echo
  echo "ERROR: Installation failed at line $line_number with exit code $exit_code"
  echo "Please check the error above and try again."
  exit "$exit_code"
}

# Root check
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
# No default username to avoid storing credentials in repo
USERNAME="${USERNAME:-}"
TIMEZONE="${TIMEZONE:-America/New_York}"
LOCALE="${LOCALE:-en_US.UTF-8}"
# Default repo points to rockandrollprophet, can be overridden at prompt
REPO_URL="${REPO_URL:-https://github.com/rockandrollprophet/anthonyware}"

# Prompt for values if not set
read -rp "Target disk [$DISK]: " INPUT && [[ -n "$INPUT" ]] && DISK="$INPUT"

# Validate disk exists and is a block device
if ! [[ -b "$DISK" ]]; then
  echo "ERROR: Disk $DISK not found or is not a block device."
  echo "Available disks:"
  lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
  echo
  echo "Please specify a valid disk (e.g., /dev/nvme0n1, /dev/sda)"
  exit 1
fi

# Warn if disk is mounted
if mount | grep -q "^${DISK}"; then
  echo "WARNING: $DISK or its partitions are currently mounted."
  echo "This may cause issues. Consider unmounting before proceeding."
  read -rp "Continue anyway? [y/N] " ans
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

read -rp "Hostname [$HOSTNAME]: " INPUT && [[ -n "$INPUT" ]] && HOSTNAME="$INPUT"
read -rp "Timezone [$TIMEZONE]: " INPUT && [[ -n "$INPUT" ]] && TIMEZONE="$INPUT"
read -rp "Locale [$LOCALE]: " INPUT && [[ -n "$INPUT" ]] && LOCALE="$INPUT"
read -rp "Repository URL [$REPO_URL]: " INPUT && [[ -n "$INPUT" ]] && REPO_URL="$INPUT"

echo
echo "============================================================================"
echo " USER ACCOUNT SETUP"
echo "============================================================================"
echo
echo "This installer does NOT create user accounts or set passwords."
echo "You will set these up MANUALLY after the base system installs."
echo
echo "After installation completes and the system reboots:"
echo "  1. Login as 'root' (no password set yet)"
echo "  2. Create your user account with useradd"
echo "  3. Set passwords with passwd"
echo "  4. Add user to wheel group for sudo access"
echo
echo "See INSTALL_INSTRUCTIONS.md for detailed post-install steps."
echo "============================================================================"
echo

# ============================================================
#  VERIFICATION
# ============================================================

echo "╔══════════════════════════════════════════════════════╗"
echo "║ Anthonyware OS 1.0 Installer                         ║"
echo "╚══════════════════════════════════════════════════════╝"
echo
echo "Target disk:    $DISK"
echo "Hostname:       $HOSTNAME"
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

# Validate disk exists
if ! [[ -b "$DISK" ]]; then
  echo "ERROR: Disk $DISK not found." >&2
  echo "Available disks:"
  lsblk -d -n -o NAME,SIZE,TYPE | grep disk
  exit 1
fi

# Check if disk is mounted
if mount | grep -q "^${DISK}"; then
  echo "ERROR: $DISK is currently mounted. Unmount before proceeding." >&2
  exit 1
fi

# Wipe filesystem signatures
if ! wipefs -a "$DISK" 2>/dev/null; then
  echo "WARNING: Failed to wipe filesystem signatures" >&2
fi

# Create partition table (GPT)
if ! sgdisk -Z "$DISK" 2>/dev/null; then
  echo "WARNING: Failed to zap partition table, continuing..." >&2
fi
sleep 1

# Create EFI partition (512 MiB)
if ! sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" "$DISK"; then
  echo "ERROR: Failed to create EFI partition" >&2
  exit 1
fi

# Create root partition (remaining space)
if ! sgdisk -n 2:0:0 -t 2:8300 -c 2:"ROOT" "$DISK"; then
  echo "ERROR: Failed to create root partition" >&2
  exit 1
fi

# Inform kernel of partition changes
partprobe "$DISK" 2>/dev/null || sleep 2

# Determine partition naming scheme
if [[ "$DISK" =~ nvme ]]; then
  EFI="${DISK}p1"
  ROOT="${DISK}p2"
else
  EFI="${DISK}1"
  ROOT="${DISK}2"
fi

# Verify partitions exist
if ! [[ -b "$EFI" ]]; then
  echo "ERROR: EFI partition $EFI not found after creation" >&2
  exit 1
fi

if ! [[ -b "$ROOT" ]]; then
  echo "ERROR: ROOT partition $ROOT not found after creation" >&2
  exit 1
fi

echo "✓ Partitioning complete"
echo "  EFI:  $EFI"
echo "  ROOT: $ROOT"

# ============================================================
#  FORMATTING
# ============================================================

echo
echo "[2/6] Formatting..."

# Format EFI partition
if ! mkfs.fat -F32 "$EFI" >/dev/null 2>&1; then
  echo "ERROR: Failed to format EFI partition $EFI" >&2
  exit 1
fi

# Format root partition
if ! mkfs.btrfs -f "$ROOT" >/dev/null 2>&1; then
  echo "ERROR: Failed to format root partition $ROOT with Btrfs" >&2
  exit 1
fi

echo "✓ Filesystems created"

# ============================================================
#  BTRFS SUBVOLUMES
# ============================================================

echo
echo "[3/6] Creating Btrfs subvolumes..."

# Mount root partition
if ! mount "$ROOT" /mnt; then
  echo "ERROR: Failed to mount $ROOT to /mnt" >&2
  exit 1
fi

# Create subvolumes
for subvol in @ @home @log @pkg @snapshots; do
  if ! btrfs subvolume create "/mnt/$subvol"; then
    echo "ERROR: Failed to create subvolume $subvol" >&2
    umount /mnt || true
    exit 1
  fi
done

# Unmount before remounting with subvolumes
if ! umount /mnt; then
  echo "ERROR: Failed to unmount /mnt" >&2
  exit 1
fi

echo "✓ Subvolumes created"

# ============================================================
#  MOUNTING
# ============================================================

echo
echo "[4/6] Mounting filesystems..."

# Mount root subvolume
if ! mount -o subvol=@,compress=zstd,relatime "$ROOT" /mnt; then
  echo "ERROR: Failed to mount root subvolume"
  exit 1
fi

# Verify root mount
if ! mountpoint -q /mnt; then
  echo "ERROR: /mnt is not a mountpoint after mount operation"
  exit 1
fi

# Create mount points with error checking
if ! mkdir -p /mnt/{boot,home,var/{log,cache/pacman/pkg},.snapshots}; then
  echo "ERROR: Failed to create mount point directories"
  exit 1
fi

# Mount other subvolumes with validation
echo "Mounting @home subvolume..."
if ! mount -o subvol=@home,compress=zstd,relatime "$ROOT" /mnt/home; then
  echo "ERROR: Failed to mount @home subvolume"
  exit 1
fi

echo "Mounting @log subvolume..."
if ! mount -o subvol=@log,compress=zstd,relatime "$ROOT" /mnt/var/log; then
  echo "ERROR: Failed to mount @log subvolume"
  exit 1
fi

echo "Mounting @pkg subvolume..."
if ! mount -o subvol=@pkg,compress=zstd,relatime "$ROOT" /mnt/var/cache/pacman/pkg; then
  echo "ERROR: Failed to mount @pkg subvolume"
  exit 1
fi

echo "Mounting @snapshots subvolume..."
if ! mount -o subvol=@snapshots,compress=zstd,relatime "$ROOT" /mnt/.snapshots; then
  echo "ERROR: Failed to mount @snapshots subvolume"
  exit 1
fi

# Mount EFI partition
echo "Mounting EFI partition..."
if ! mount "$EFI" /mnt/boot; then
  echo "ERROR: Failed to mount EFI partition at /mnt/boot"
  exit 1
fi

# Verify all critical mount points
for mp in /mnt /mnt/home /mnt/var/log /mnt/boot; do
  if ! mountpoint -q "$mp"; then
    echo "ERROR: $mp failed mountpoint verification"
    exit 1
  fi
done

echo "✓ Filesystems mounted and verified"

# ============================================================
#  BASE SYSTEM
# ============================================================

echo
echo "[5/6] Installing base system (this may take several minutes)..."

# Pre-create vconsole.conf in target to satisfy mkinitcpio console hook
# This avoids the common warning during kernel/initramfs build
if ! mkdir -p /mnt/etc; then
  echo "ERROR: Failed to create /mnt/etc directory"
  exit 1
fi
echo "KEYMAP=us" > /mnt/etc/vconsole.conf

# Validate network connectivity before attempting package installation
if ! ping -c 1 archlinux.org &>/dev/null; then
  echo "ERROR: No network connectivity. Cannot install packages."
  echo "       Check your network connection and try again."
  exit 1
fi

# Install base system with error checking
echo "Running pacstrap..."
if ! pacstrap -K /mnt base base-devel linux linux-firmware linux-headers \
  networkmanager sudo git btrfs-progs grub efibootmgr; then
  echo "ERROR: pacstrap failed to install base system"
  echo "       This is usually caused by network issues or mirror problems."
  echo "       Try running: reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist"
  exit 1
fi

# Verify critical packages were installed
CRITICAL_PKGS=("base" "linux" "networkmanager" "grub")
for pkg in "${CRITICAL_PKGS[@]}"; do
  if ! arch-chroot /mnt pacman -Q "$pkg" &>/dev/null; then
    echo "ERROR: Critical package '$pkg' was not installed"
    exit 1
  fi
done

# Generate fstab with validation
echo "Generating fstab..."
if ! genfstab -U /mnt >> /mnt/etc/fstab; then
  echo "ERROR: Failed to generate fstab"
  exit 1
fi

# Verify fstab was created and contains entries
if [[ ! -s /mnt/etc/fstab ]]; then
  echo "ERROR: fstab file is empty or does not exist"
  exit 1
fi

# Count fstab entries (should have at least 5: root, home, log, pkg, boot)
FSTAB_ENTRIES=$(grep -c "^UUID=" /mnt/etc/fstab || true)
if [[ "$FSTAB_ENTRIES" -lt 5 ]]; then
  echo "WARNING: fstab has fewer entries than expected ($FSTAB_ENTRIES found, expected at least 5)"
  echo "         Continuing, but verify /mnt/etc/fstab after installation."
fi

echo "✓ Base system installed and verified"

# ============================================================
#  CHROOT PHASE
# ============================================================

echo
echo "[6/6] Configuring system in chroot..."

# Validation check removed - passwords no longer captured
if [[ -z "$HOSTNAME" ]]; then
  echo "ERROR: Hostname is empty"
  exit 1
fi

# Run chroot configuration WITHOUT user creation (manual post-install)
env \
  HOSTNAME="$HOSTNAME" \
  TIMEZONE="$TIMEZONE" \
  LOCALE="$LOCALE" \
  REPO_URL="$REPO_URL" \
  arch-chroot /mnt /bin/bash << 'CHROOT_EOF'
set -eo pipefail

# ---- Timezone & Locale ----
echo "Setting timezone..."
if ! ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime; then
  echo "ERROR: Failed to set timezone"
  exit 1
fi

if ! hwclock --systohc; then
  echo "WARNING: hwclock failed (this may be normal in VMs)"
fi

echo "Generating locale..."
if ! sed -i "s/#${LOCALE}/${LOCALE}/" /etc/locale.gen; then
  echo "ERROR: Failed to enable locale in /etc/locale.gen"
  exit 1
fi

if ! locale-gen; then
  echo "ERROR: locale-gen failed"
  exit 1
fi

echo "LANG=${LOCALE}" > /etc/locale.conf

# ---- Hostname & Network ----
echo "Setting hostname..."
echo "$HOSTNAME" > /etc/hostname

if [[ ! -s /etc/hostname ]]; then
  echo "ERROR: Failed to write hostname"
  exit 1
fi

echo "Enabling NetworkManager..."
if ! systemctl enable NetworkManager; then
  echo "ERROR: Failed to enable NetworkManager"
  exit 1
fi

# Ensure vconsole exists to keep mkinitcpio happy
if [[ ! -f /etc/vconsole.conf ]]; then
  echo "KEYMAP=us" > /etc/vconsole.conf
fi

# ---- Bootloader ----
echo "Installing GRUB bootloader..."
if ! grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB; then
  echo "ERROR: GRUB installation failed"
  exit 1
fi

if ! grub-mkconfig -o /boot/grub/grub.cfg; then
  echo "ERROR: GRUB configuration generation failed"
  exit 1
fi

# Verify GRUB was installed
if [[ ! -f /boot/grub/grub.cfg ]]; then
  echo "ERROR: GRUB config file not found after installation"
  exit 1
fi

# ---- Create installation directories for post-setup ----
mkdir -p /root/anthonyware-setup

# Clone repository to /root for manual user setup later
echo "Cloning Anthonyware repository to /root..."
if ! git clone "$REPO_URL" /root/anthonyware-setup/anthonyware; then
  echo "WARNING: Failed to clone repository"
  echo "         URL: $REPO_URL"
  echo "         You can clone it manually after first boot."
else
  echo "✓ Repository cloned to /root/anthonyware-setup/anthonyware"
fi

echo "=== Base system configuration complete ==="
echo
echo "USER ACCOUNT MUST BE CREATED MANUALLY AFTER REBOOT"
echo "See INSTALL_INSTRUCTIONS.md for detailed steps"

CHROOT_EOF

# ============================================================
#  CLEANUP & REBOOT
# ============================================================

echo
echo "╔══════════════════════════════════════════════════════╗"
echo "║ Base System Installation Complete                    ║"
echo "╚══════════════════════════════════════════════════════╝"
echo
echo "Base Arch system installed and configured."
echo
echo "Unmounting filesystems..."
umount -R /mnt >/dev/null 2>&1 || true

echo
echo "Configuration Summary:"
echo "  Hostname:  $HOSTNAME"
echo "  Timezone:  $TIMEZONE"
echo "  Locale:    $LOCALE"
echo
echo "╔══════════════════════════════════════════════════════╗"
echo "║ CRITICAL: USER SETUP REQUIRED                        ║"
echo "╚══════════════════════════════════════════════════════╝"
echo
echo "After reboot, you MUST manually:"
echo "  1. Boot to root prompt (no password set yet)"
echo "  2. Create your user account"
echo "  3. Set passwords for user and root"
echo "  4. Add user to wheel group for sudo"
echo "  5. Run the installation pipeline as your user"
echo
echo "Detailed instructions: /root/anthonyware-setup/anthonyware/INSTALL_INSTRUCTIONS.md"
echo
read -rp "Reboot now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  reboot
else
  echo "Ready to reboot when you are. Run: sudo reboot"
fi
