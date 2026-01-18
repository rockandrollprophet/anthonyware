#!/usr/bin/env bash
# offline-prepare.sh - Prepare offline installation cache

set -euo pipefail

OFFLINE_CACHE="${OFFLINE_CACHE:-/var/cache/anthonyware-offline}"
PACKAGE_CACHE="$OFFLINE_CACHE/packages"
REPO_CACHE="$OFFLINE_CACHE/repos"

echo "Preparing offline installation cache at $OFFLINE_CACHE..."
mkdir -p "$PACKAGE_CACHE" "$REPO_CACHE"

# Essential packages list for minimal install
ESSENTIAL_PKGS=(
  "base" "base-devel" "linux" "linux-firmware"
  "git" "wget" "curl" "networkmanager"
  "hyprland" "hyprpaper" "hyprlock" "hypridle"
  "kitty" "waybar" "wofi" "mako" "swaync"
  "firefox" "thunar" "pavucontrol"
  "pipewire" "pipewire-pulse" "wireplumber"
  "sddm" "qt6-base" "qt6-wayland"
  "ttf-dejavu" "ttf-liberation" "noto-fonts"
)

# Download packages
echo "Downloading essential packages..."
for pkg in "${ESSENTIAL_PKGS[@]}"; do
  echo "  Downloading $pkg..."
  if ! pacman -Sw --noconfirm "$pkg" 2>/dev/null; then
    echo "    Warning: Failed to download $pkg"
  fi
done

# Copy downloaded packages to offline cache
echo "Copying packages to offline cache..."
if [[ -d /var/cache/pacman/pkg ]]; then
  cp -u /var/cache/pacman/pkg/*.pkg.tar.zst "$PACKAGE_CACHE/" 2>/dev/null || true
fi

# Create package database
echo "Creating package database..."
repo-add "$PACKAGE_CACHE/offline.db.tar.gz" "$PACKAGE_CACHE"/*.pkg.tar.zst 2>/dev/null || true

# Clone or update repository
echo "Caching repository..."
REPO_URL="${REPO_URL:-https://github.com/yourusername/anthonyware.git}"
if [[ -d "$REPO_CACHE/anthonyware" ]]; then
  cd "$REPO_CACHE/anthonyware"
  git pull || echo "Warning: Could not update repository"
else
  git clone "$REPO_URL" "$REPO_CACHE/anthonyware" || echo "Warning: Could not clone repository"
fi

# Create offline configuration
cat > "$OFFLINE_CACHE/offline-config.sh" <<'EOF'
#!/usr/bin/env bash
# Offline installation configuration

export OFFLINE_MODE=1
export OFFLINE_CACHE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PACKAGE_CACHE="$OFFLINE_CACHE/packages"
export REPO_PATH="$OFFLINE_CACHE/repos/anthonyware"

# Configure pacman to use offline cache
pacman_offline_setup() {
  echo "Configuring pacman for offline mode..."
  
  # Add local repository to pacman.conf
  if ! grep -q "anthonyware-offline" /etc/pacman.conf; then
    cat >> /etc/pacman.conf <<CONF

[anthonyware-offline]
SigLevel = Optional TrustAll
Server = file://${PACKAGE_CACHE}
CONF
  fi
  
  # Sync databases
  pacman -Sy
}

echo "Offline cache configured at $OFFLINE_CACHE"
echo "Run: source offline-config.sh && pacman_offline_setup"
EOF

chmod +x "$OFFLINE_CACHE/offline-config.sh"

# Generate usage instructions
cat > "$OFFLINE_CACHE/README.txt" <<'EOF'
ANTHONYWARE OFFLINE INSTALLATION CACHE
======================================

This directory contains packages and repository files for offline installation.

USAGE:
1. Copy this entire directory to target system (USB, network share, etc.)
2. On target system, run:
   source /path/to/offline-cache/offline-config.sh
   pacman_offline_setup
3. Run installation with OFFLINE_MODE=1:
   cd repos/anthonyware
   sudo OFFLINE_MODE=1 CONFIRM_INSTALL=YES bash install/run-all.sh

CONTENTS:
- packages/: Cached package files and database
- repos/: Cloned anthonyware repository
- offline-config.sh: Configuration script

UPDATING:
Re-run offline-prepare.sh to update packages and repository.

NOTE: Offline mode has limitations:
- AUR packages will be skipped
- External downloads (fonts, etc.) may fail
- Some scripts may require network for verification
EOF

echo
echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Offline Cache Prepared                                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo
echo "Location: $OFFLINE_CACHE"
echo "Size: $(du -sh "$OFFLINE_CACHE" | cut -f1)"
echo "Packages: $(ls -1 "$PACKAGE_CACHE"/*.pkg.tar.zst 2>/dev/null | wc -l)"
echo
echo "See $OFFLINE_CACHE/README.txt for usage instructions"
echo
