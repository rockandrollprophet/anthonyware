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

# Require non-empty username
while true; do
  read -rp "Username: " USERNAME
  if [[ -n "$USERNAME" ]]; then
    break
  else
    echo "Username cannot be empty."
  fi
done

# Prompt for passwords with confirmation
prompt_secret() {
  local prompt="$1" v1 v2
  while true; do
    read -rsp "$prompt" v1 && echo
    if [[ -z "$v1" ]]; then
      echo "ERROR: Password cannot be empty. Try again."
      continue
    fi
    read -rsp "Confirm $prompt" v2 && echo
    if [[ "$v1" == "$v2" ]]; then
      printf "%s" "$v1"
      return 0
    else
      echo "ERROR: Passwords do not match. Try again."
    fi
  done
}

PASSWORD=$(prompt_secret "User password: ")
ROOT_PASSWORD=$(prompt_secret "Root password: ")

# Final validation that passwords were captured
if [[ -z "$PASSWORD" ]] || [[ -z "$ROOT_PASSWORD" ]]; then
  echo "ERROR: Password capture failed. Please restart the installer."
  exit 1
fi

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

# Validate passwords before proceeding
if [[ -z "$PASSWORD" ]]; then
  echo "ERROR: User password is empty"
  exit 1
fi

if [[ -z "$ROOT_PASSWORD" ]]; then
  echo "ERROR: Root password is empty"
  exit 1
fi

# Run chroot configuration with comprehensive error handling
env \
  CHROOT_PASSWORD="$PASSWORD" \
  CHROOT_ROOT_PASSWORD="$ROOT_PASSWORD" \
  USERNAME="$USERNAME" \
  HOSTNAME="$HOSTNAME" \
  TIMEZONE="$TIMEZONE" \
  LOCALE="$LOCALE" \
  REPO_URL="$REPO_URL" \
  arch-chroot /mnt /bin/bash << 'CHROOT_EOF'
# Use -e and pipefail; skip -u to avoid unbound variable exits when values are empty
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

# ---- User Management ----
echo "Creating user: $USERNAME"
if ! useradd -m -s /bin/bash "$USERNAME" 2>/dev/null; then
  if id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME already exists, continuing..."
  else
    echo "ERROR: Failed to create user $USERNAME"
    exit 1
  fi
fi

# Ensure vconsole exists to keep mkinitcpio happy
if [[ ! -f /etc/vconsole.conf ]]; then
  echo "KEYMAP=us" > /etc/vconsole.conf
fi

# Set passwords from environment passed into chroot
echo "Setting passwords..."

if [[ -z "${CHROOT_PASSWORD:-}" ]] || [[ -z "${CHROOT_ROOT_PASSWORD:-}" ]]; then
  echo "ERROR: Password variables not found in chroot"
  exit 1
fi

echo "Setting user password..."
echo "$CHROOT_PASSWORD" | passwd --stdin "$USERNAME"

echo "Setting root password..."
echo "$CHROOT_ROOT_PASSWORD" | passwd --stdin root

# Grant wheel group passwordless sudo (temporary for installation)
if ! sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers; then
  echo "ERROR: Failed to modify sudoers for passwordless sudo"
  exit 1
fi

if ! usermod -aG wheel "$USERNAME"; then
  echo "ERROR: Failed to add user to wheel group"
  exit 1
fi

# Add to additional groups (ignore failures for groups that may not exist yet)
usermod -aG docker,libvirt "$USERNAME" 2>/dev/null || true

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

# ---- Set up repository ----
echo "Cloning Anthonyware repository..."
REPO_PATH="/home/$USERNAME/anthonyware"

if ! sudo -u "$USERNAME" git clone "$REPO_URL" "\$REPO_PATH"; then
  echo "WARNING: Failed to clone repository"
  echo "         URL: $REPO_URL"
  echo "         You can clone it manually after first boot."
else
  echo "✓ Repository cloned successfully"
fi

# ---- Run installer pipeline ----
if [[ -d "\$REPO_PATH/install" ]]; then
  echo "Running Anthonyware installation pipeline..."
  cd "\$REPO_PATH/install"
  
  export TARGET_USER="$USERNAME"
  export TARGET_HOME="/home/$USERNAME"
  export REPO_PATH="\$REPO_PATH"
  
  if sudo TARGET_USER="\$TARGET_USER" TARGET_HOME="\$TARGET_HOME" REPO_PATH="\$REPO_PATH" bash run-all.sh; then
    echo "✓ Installation pipeline completed"
  else
    echo "WARNING: Installation pipeline encountered errors"
    echo "         Check logs in /home/$USERNAME/anthonyware/install/"
  fi
else
  echo "WARNING: install directory not found in cloned repo at \$REPO_PATH/install"
fi

# ---- Restore password-required sudo ----
echo "Restoring password-required sudo..."
if ! sed -i 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers; then
  echo "ERROR: Failed to restore sudoers (remove NOPASSWD)"
  exit 1
fi

if ! sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers; then
  echo "ERROR: Failed to restore sudoers (enable password-required sudo)"
  exit 1
fi

echo "=== Chroot configuration complete ==="

CHROOT_EOF

# Copy password file into chroot before running (insert above the heredoc)
# Actually, we need to insert this BEFORE the heredoc runs
# Let me fix the flow properly

# Clean up password file
rm -f "$PASS_FILE"

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
