#!/usr/bin/env bash
# safety.sh - Comprehensive safety checks and validation functions

# ============================================================
# Pre-flight Safety Checks
# ============================================================

# Check if running as root or with sudo access
safety_check_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    if ! sudo -n true 2>/dev/null; then
      echo "ERROR: This script requires root access or passwordless sudo"
      echo "Please run with: sudo bash install/run-all.sh"
      return 1
    fi
  fi
  return 0
}

# Check available disk space (require minimum GB)
safety_check_disk_space() {
  local required_gb="${1:-10}"
  local available_kb
  available_kb=$(df / | tail -1 | awk '{print $4}')
  local available_gb=$((available_kb / 1024 / 1024))
  
  if [[ $available_gb -lt $required_gb ]]; then
    echo "ERROR: Insufficient disk space"
    echo "  Required: ${required_gb}GB"
    echo "  Available: ${available_gb}GB"
    echo ""
    echo "Free up space and try again:"
    echo "  sudo pacman -Scc        # Clean package cache"
    echo "  sudo journalctl --vacuum-time=2weeks"
    echo "  ncdu /                  # Find large directories"
    return 1
  fi
  
  echo "✓ Disk space check: ${available_gb}GB available (need ${required_gb}GB)"
  return 0
}

# Check network connectivity with retries
safety_check_network() {
  local hosts=("archlinux.org" "aur.archlinux.org" "github.com")
  local reachable=0
  
  echo "Checking network connectivity..."
  for host in "${hosts[@]}"; do
    if ping -c 1 -W 3 "$host" >/dev/null 2>&1; then
      echo "  ✓ $host reachable"
      ((reachable++))
    else
      echo "  ✗ $host unreachable"
    fi
  done
  
  if [[ $reachable -eq 0 ]]; then
    echo "ERROR: No network connectivity detected"
    echo "Check your network connection and try again"
    return 1
  elif [[ $reachable -lt ${#hosts[@]} ]]; then
    echo "WARNING: Some hosts unreachable (${reachable}/${#hosts[@]} reachable)"
    echo "Installation may encounter issues"
    return 2
  fi
  
  echo "✓ Network check: All hosts reachable"
  return 0
}

# Check if pacman is locked
safety_check_pacman_lock() {
  if [[ -f /var/lib/pacman/db.lck ]]; then
    if pgrep -x pacman >/dev/null 2>&1; then
      echo "ERROR: pacman is currently running (PID: $(pgrep -x pacman))"
      echo "Wait for the current operation to complete, or if stuck:"
      echo "  sudo kill $(pgrep -x pacman)"
      echo "  sudo rm /var/lib/pacman/db.lck"
      return 1
    else
      echo "WARNING: Stale pacman lock detected, removing..."
      sudo rm -f /var/lib/pacman/db.lck
      echo "✓ Lock removed"
    fi
  fi
  
  echo "✓ Pacman lock check: No conflicts"
  return 0
}

# Verify system is not a live ISO
safety_check_not_live_iso() {
  if [[ -d /run/archiso ]] || [[ -f /etc/archlive ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "ERROR: Live ISO Environment Detected"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This installer should NOT be run from a live ISO."
    echo "Running it would install to the live medium, which"
    echo "will be lost after reboot."
    echo ""
    echo "CORRECT PROCEDURE:"
    echo "  1. Boot into your INSTALLED Arch Linux system"
    echo "  2. Clone the anthonyware repository"
    echo "  3. Run this installer from the installed system"
    echo ""
    echo "If you haven't installed Arch yet:"
    echo "  • Follow the Arch Installation Guide first"
    echo "  • Install base system to your hard drive"
    echo "  • Boot into it, then run this installer"
    echo ""
    return 1
  fi
  
  echo "✓ Not running from live ISO"
  return 0
}

# Run all safety checks
safety_check_all() {
  local errors=0
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Pre-Flight Safety Checks"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  safety_check_not_live_iso || ((errors++))
  safety_check_root || ((errors++))
  safety_check_disk_space 10 || ((errors++))
  safety_check_pacman_lock || ((errors++))
  safety_check_network || {
    local ret=$?
    [[ $ret -eq 1 ]] && ((errors++))
  }
  
  echo ""
  if [[ $errors -gt 0 ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ Safety checks failed: $errors error(s)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    return 1
  else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ All safety checks passed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    return 0
  fi
}

# ============================================================
# Safe Command Wrappers
# ============================================================

# Safe pacman command with error handling
safe_pacman() {
  local operation="$1"
  shift
  local packages=("$@")
  
  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "WARNING: safe_pacman called with no packages, skipping"
    return 0
  fi
  
  echo "Installing packages: ${packages[*]}"
  
  local sudo_cmd=""
  [[ "${EUID}" -ne 0 ]] && sudo_cmd="sudo"
  
  if ! $sudo_cmd pacman "$operation" --noconfirm --needed "${packages[@]}" 2>&1 | tee /tmp/pacman-install.log; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "ERROR: Package installation failed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Failed packages: ${packages[*]}"
    echo ""
    echo "Common causes:"
    echo "  • Conflicting packages already installed"
    echo "  • Outdated package database (try: sudo pacman -Sy)"
    echo "  • Network issues downloading packages"
    echo "  • Corrupted package cache"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Update package database:"
    echo "     sudo pacman -Sy"
    echo "  2. Check for conflicts:"
    echo "     pacman -Qi <package>"
    echo "  3. Clear package cache:"
    echo "     sudo pacman -Scc"
    echo "  4. View full log:"
    echo "     less /tmp/pacman-install.log"
    echo ""
    return 1
  fi
  
  echo "✓ Packages installed successfully"
  return 0
}

# Safe service enablement with validation
safe_enable_service() {
  local service="$1"
  local description="${2:-$service}"
  
  local sudo_cmd=""
  [[ "${EUID}" -ne 0 ]] && sudo_cmd="sudo"
  
  # Check if service unit file exists
  if ! systemctl list-unit-files | grep -q "^${service}.service"; then
    echo "⊙ Service ${description} not available (package may not be installed)"
    return 0
  fi
  
  # Check if already enabled
  if systemctl is-enabled --quiet "${service}" 2>/dev/null; then
    echo "✓ ${description} already enabled"
    
    # Try to start if not running
    if ! systemctl is-active --quiet "${service}" 2>/dev/null; then
      if $sudo_cmd systemctl start "${service}" 2>&1; then
        echo "  ✓ Started ${description}"
      else
        echo "  ⚠ ${description} enabled but failed to start"
      fi
    fi
    
    return 0
  fi
  
  # Enable and start service
  if $sudo_cmd systemctl enable --now "${service}" 2>&1; then
    echo "✓ Enabled and started ${description}"
    return 0
  else
    echo "⚠ Failed to enable ${description}"
    echo "  You can try manually: sudo systemctl enable --now ${service}"
    return 1
  fi
}

# Safe AUR helper installation
safe_install_yay() {
  if command -v yay >/dev/null 2>&1; then
    echo "✓ yay already installed"
    return 0
  fi
  
  echo "Installing yay AUR helper..."
  echo "This will take a few minutes..."
  
  # Install dependencies
  safe_pacman -S base-devel git || {
    echo "ERROR: Failed to install yay dependencies"
    return 1
  }
  
  # Clone yay repository
  local yay_dir="/tmp/yay-install-$$"
  if ! git clone https://aur.archlinux.org/yay.git "$yay_dir" 2>&1; then
    echo "ERROR: Failed to clone yay repository"
    echo "Check network connectivity to aur.archlinux.org"
    return 1
  fi
  
  # Build and install
  (
    cd "$yay_dir" || exit 1
    if ! makepkg -si --noconfirm; then
      echo "ERROR: Failed to build yay"
      return 1
    fi
  ) || {
    rm -rf "$yay_dir"
    return 1
  }
  
  rm -rf "$yay_dir"
  
  # Verify installation
  if ! command -v yay >/dev/null 2>&1; then
    echo "ERROR: yay installation failed verification"
    return 1
  fi
  
  echo "✓ yay installed successfully"
  return 0
}

# Safe cleanup of orphaned packages
safe_clean_orphans() {
  local orphans
  orphans=$(pacman -Qtdq 2>/dev/null || true)
  
  if [[ -z "$orphans" ]]; then
    echo "✓ No orphaned packages found"
    return 0
  fi
  
  local count
  count=$(echo "$orphans" | wc -l)
  
  echo "Found $count orphaned package(s):"
  echo "$orphans" | sed 's/^/  • /'
  echo ""
  echo "Removing orphaned packages..."
  
  local sudo_cmd=""
  [[ "${EUID}" -ne 0 ]] && sudo_cmd="sudo"
  
  if ! echo "$orphans" | xargs $sudo_cmd pacman -Rns --noconfirm 2>&1; then
    echo "⚠ Some orphaned packages could not be removed"
    echo "  This is usually safe to ignore"
    return 0
  fi
  
  echo "✓ Removed $count orphaned package(s)"
  return 0
}

# Safe directory creation with ownership
safe_mkdir() {
  local dir="$1"
  local owner="${2:-}"
  local mode="${3:-0755}"
  
  local sudo_cmd=""
  [[ "${EUID}" -ne 0 ]] && sudo_cmd="sudo"
  
  if [[ -d "$dir" ]]; then
    return 0
  fi
  
  if ! $sudo_cmd mkdir -p "$dir"; then
    echo "ERROR: Failed to create directory: $dir"
    return 1
  fi
  
  if [[ -n "$owner" ]]; then
    $sudo_cmd chown "$owner:$owner" "$dir" || true
  fi
  
  $sudo_cmd chmod "$mode" "$dir" || true
  
  return 0
}

# Safe GRUB configuration update with validation
safe_update_grub() {
  local description="$1"
  
  local sudo_cmd=""
  [[ "${EUID}" -ne 0 ]] && sudo_cmd="sudo"
  
  if ! command -v grub-mkconfig >/dev/null 2>&1; then
    echo "⊙ GRUB not installed, skipping bootloader update"
    return 0
  fi
  
  if [[ ! -f /etc/default/grub ]]; then
    echo "⚠ /etc/default/grub not found, skipping bootloader update"
    return 0
  fi
  
  echo "Updating GRUB configuration: $description"
  
  # Validate GRUB config syntax
  if ! grep -qE '^GRUB_CMDLINE_LINUX=' /etc/default/grub; then
    echo "ERROR: Invalid /etc/default/grub (missing GRUB_CMDLINE_LINUX)"
    return 1
  fi
  
  # Generate new config to test file
  if ! $sudo_cmd grub-mkconfig -o /boot/grub/grub.cfg.test 2>&1 | grep -q "Generating"; then
    echo "ERROR: grub-mkconfig validation failed"
    echo "  Check kernel and GRUB installation"
    rm -f /boot/grub/grub.cfg.test
    return 1
  fi
  
  # Apply validated config
  $sudo_cmd mv /boot/grub/grub.cfg.test /boot/grub/grub.cfg
  
  echo "✓ GRUB configuration updated"
  return 0
}

# Safe mkinitcpio update with validation
safe_update_initramfs() {
  local description="$1"
  
  local sudo_cmd=""
  [[ "${EUID}" -ne 0 ]] && sudo_cmd="sudo"
  
  if ! command -v mkinitcpio >/dev/null 2>&1; then
    echo "⊙ mkinitcpio not available, skipping initramfs update"
    return 0
  fi
  
  if [[ ! -f /etc/mkinitcpio.conf ]]; then
    echo "⊙ /etc/mkinitcpio.conf not found, skipping initramfs update"
    return 0
  fi
  
  echo "Updating initramfs: $description"
  
  # Validate mkinitcpio.conf syntax
  if ! grep -qE '^HOOKS=\([^)]+\)' /etc/mkinitcpio.conf; then
    echo "ERROR: Invalid /etc/mkinitcpio.conf (malformed HOOKS line)"
    return 1
  fi
  
  # Regenerate initramfs
  if ! $sudo_cmd mkinitcpio -P 2>&1 | tee /tmp/mkinitcpio.log; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "ERROR: Initramfs generation failed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This usually means:"
    echo "  • Missing kernel modules"
    echo "  • Invalid HOOKS in /etc/mkinitcpio.conf"
    echo "  • Corrupted kernel installation"
    echo ""
    echo "View full log:"
    echo "  less /tmp/mkinitcpio.log"
    echo ""
    return 1
  fi
  
  echo "✓ Initramfs updated successfully"
  return 0
}

# Export functions
export -f safety_check_root
export -f safety_check_disk_space
export -f safety_check_network
export -f safety_check_pacman_lock
export -f safety_check_not_live_iso
export -f safety_check_all
export -f safe_pacman
export -f safe_enable_service
export -f safe_install_yay
export -f safe_clean_orphans
export -f safe_mkdir
export -f safe_update_grub
export -f safe_update_initramfs
