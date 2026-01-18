#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# version-pin.sh - Package version pinning for reproducible installations

LOCK_FILE="${REPO_PATH:-$(dirname "$(dirname "$(readlink -f "$0")")")}/versions.lock"
PACMAN_IGNORE_FILE="/etc/pacman.d/anthonyware-ignore.conf"

# Parse version lock file
parse_lock_file() {
  local section=""
  local -A packages
  
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue
    
    # Parse section headers
    if [[ "$line" =~ ^\[([^]]+)\] ]]; then
      section="${BASH_REMATCH[1]}"
      continue
    fi
    
    # Parse package=version
    if [[ "$line" =~ ^([^=]+)=(.+)$ ]]; then
      local pkg="${BASH_REMATCH[1]}"
      local ver="${BASH_REMATCH[2]}"
      echo "$pkg=$ver"
    fi
  done < "$LOCK_FILE"
}

# Lock versions - prevent updates
lock_versions() {
  if [[ ! -f "$LOCK_FILE" ]]; then
    echo "ERROR: Lock file not found: $LOCK_FILE"
    return 1
  fi
  
  echo "Locking package versions..."
  
  # Create ignore patterns for pacman
  local ignore_list=()
  while IFS= read -r entry; do
    local pkg="${entry%=*}"
    ignore_list+=("$pkg")
  done < <(parse_lock_file)
  
  # Write to pacman config
  {
    echo "# Anthonyware version pinning"
    echo "# Generated: $(date)"
    echo "IgnorePkg = ${ignore_list[*]}"
  } > "$PACMAN_IGNORE_FILE"
  
  # Include in main pacman.conf if not already
  if ! grep -q "Include = $PACMAN_IGNORE_FILE" /etc/pacman.conf; then
    echo "Include = $PACMAN_IGNORE_FILE" >> /etc/pacman.conf
  fi
  
  echo "✓ Locked ${#ignore_list[@]} packages"
  echo "✓ Configuration written to: $PACMAN_IGNORE_FILE"
}

# Unlock versions - allow updates
unlock_versions() {
  echo "Unlocking package versions..."
  
  # Remove ignore file
  rm -f "$PACMAN_IGNORE_FILE"
  
  # Remove include from pacman.conf
  sed -i "\|Include = $PACMAN_IGNORE_FILE|d" /etc/pacman.conf
  
  echo "✓ Version pinning disabled"
}

# Install specific versions
install_pinned_versions() {
  if [[ ! -f "$LOCK_FILE" ]]; then
    echo "ERROR: Lock file not found: $LOCK_FILE"
    return 1
  fi
  
  echo "Installing pinned package versions..."
  
  # Parse lock file and install each package
  while IFS= read -r entry; do
    local pkg="${entry%=*}"
    local ver="${entry#*=}"
    
    echo "Installing $pkg=$ver..."
    
    # Check if exact version is available
    if pacman -Si "$pkg" | grep -q "Version.*$ver"; then
      pacman -S --noconfirm "$pkg=$ver" || echo "⚠ Failed to install $pkg=$ver"
    else
      echo "⚠ Version $ver not available for $pkg, installing latest"
      pacman -S --noconfirm "$pkg" || echo "⚠ Failed to install $pkg"
    fi
  done < <(parse_lock_file)
  
  echo "✓ Pinned versions installed"
}

# Show current versions
show_versions() {
  echo "Current package versions:"
  echo
  
  while IFS= read -r entry; do
    local pkg="${entry%=*}"
    local locked_ver="${entry#*=}"
    local current_ver=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}')
    
    if [[ -n "$current_ver" ]]; then
      if [[ "$current_ver" == "$locked_ver" ]]; then
        echo "✓ $pkg: $current_ver (locked)"
      else
        echo "⚠ $pkg: $current_ver (locked: $locked_ver)"
      fi
    else
      echo "✗ $pkg: not installed (locked: $locked_ver)"
    fi
  done < <(parse_lock_file)
}

# Update lock file with current versions
update_lock_file() {
  local new_lock="${LOCK_FILE}.new"
  
  echo "# Anthonyware OS Package Versions Lock File" > "$new_lock"
  echo "# Generated: $(date)" >> "$new_lock"
  echo "# Purpose: Pin package versions for reproducible installations" >> "$new_lock"
  echo >> "$new_lock"
  
  local current_section=""
  while IFS= read -r line; do
    # Preserve section headers and comments
    if [[ "$line" =~ ^\[([^]]+)\]|^[[:space:]]*# ]]; then
      echo "$line" >> "$new_lock"
      [[ "$line" =~ ^\[([^]]+)\] ]] && current_section="${BASH_REMATCH[1]}"
      continue
    fi
    
    # Update package versions
    if [[ "$line" =~ ^([^=]+)= ]]; then
      local pkg="${BASH_REMATCH[1]}"
      local current_ver=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}')
      
      if [[ -n "$current_ver" ]]; then
        echo "$pkg=$current_ver" >> "$new_lock"
      else
        echo "$line  # NOT INSTALLED" >> "$new_lock"
      fi
    elif [[ -n "$line" ]]; then
      echo "$line" >> "$new_lock"
    fi
  done < "$LOCK_FILE"
  
  mv "$new_lock" "$LOCK_FILE"
  echo "✓ Lock file updated: $LOCK_FILE"
}

# Main command handler
case "${1:-}" in
  lock)
    lock_versions
    ;;
  unlock)
    unlock_versions
    ;;
  install)
    install_pinned_versions
    ;;
  show)
    show_versions
    ;;
  update)
    update_lock_file
    ;;
  *)
    echo "Usage: $0 {lock|unlock|install|show|update}"
    echo
    echo "Commands:"
    echo "  lock    - Prevent package updates (add to IgnorePkg)"
    echo "  unlock  - Allow package updates (remove from IgnorePkg)"
    echo "  install - Install specific versions from lock file"
    echo "  show    - Show current vs locked versions"
    echo "  update  - Update lock file with current versions"
    exit 1
    ;;
esac

# Export functions
export -f parse_lock_file
export -f lock_versions
export -f unlock_versions
export -f install_pinned_versions
export -f show_versions
export -f update_lock_file
