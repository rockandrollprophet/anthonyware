#!/usr/bin/env bash
# optimize-arch.sh - Apply Arch Linux best practices and optimizations

set -euo pipefail

SUDO=""
[[ "${EUID}" -ne 0 ]] && SUDO="sudo"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Arch Linux Optimization & Best Practices"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================
# 1. Pacman Hooks
# ============================================================

echo "[1/5] Installing pacman hooks..."

# Create hooks directory
${SUDO} mkdir -p /etc/pacman.d/hooks

# Hook: Systemd daemon reload after unit file changes
cat <<'EOF' | ${SUDO} tee /etc/pacman.d/hooks/50-systemd-daemon-reload.hook >/dev/null
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = usr/lib/systemd/system/*

[Action]
Description = Reloading systemd daemon...
When = PostTransaction
Exec = /usr/bin/systemctl daemon-reload
EOF

# Hook: Update GRUB after kernel or GRUB updates
cat <<'EOF' | ${SUDO} tee /etc/pacman.d/hooks/95-grub-update.hook >/dev/null
[Trigger]
Operation = Upgrade
Type = Package
Target = linux
Target = linux-lts
Target = linux-zen
Target = grub

[Action]
Description = Updating GRUB bootloader...
When = PostTransaction
Depends = grub
Exec = /usr/bin/grub-mkconfig -o /boot/grub/grub.cfg
EOF

# Hook: Update icon cache after icon package changes
cat <<'EOF' | ${SUDO} tee /etc/pacman.d/hooks/gtk-update-icon-cache.hook >/dev/null
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = usr/share/icons/*

[Action]
Description = Updating icon cache...
When = PostTransaction
Exec = /usr/bin/gtk-update-icon-cache -f -t /usr/share/icons/hicolor
EOF

# Hook: Update font cache after font package changes
cat <<'EOF' | ${SUDO} tee /etc/pacman.d/hooks/90-fontconfig.hook >/dev/null
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = usr/share/fonts/*
Target = usr/local/share/fonts/*

[Action]
Description = Updating font cache...
When = PostTransaction
Exec = /usr/bin/fc-cache -f -s
EOF

# Hook: Clean package cache (keep last 2 versions)
cat <<'EOF' | ${SUDO} tee /etc/pacman.d/hooks/clean-package-cache.hook >/dev/null
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Cleaning package cache...
When = PostTransaction
Exec = /usr/bin/paccache -rk2
EOF

echo "✓ Pacman hooks installed (5 hooks)"

# ============================================================
# 2. systemd-tmpfiles Configuration
# ============================================================

echo ""
echo "[2/5] Configuring systemd-tmpfiles..."

# Create tmpfiles.d directory
${SUDO} mkdir -p /etc/tmpfiles.d

# Anthonyware temporary directories
cat <<'EOF' | ${SUDO} tee /etc/tmpfiles.d/anthonyware.conf >/dev/null
# Anthonyware OS temporary directories
# Type  Path                           Mode UID  GID  Age Argument

# Logs directory
d /var/log/anthonyware-install        0755 root root -   -

# Cache directory
d /var/cache/anthonyware              0755 root root 30d -

# Runtime directory
d /run/anthonyware                    0755 root root -   -

# Cleanup old installation logs (keep 90 days)
d /var/log/anthonyware-install        0755 root root 90d -
EOF

# Apply tmpfiles configuration
${SUDO} systemd-tmpfiles --create

echo "✓ systemd-tmpfiles configured"

# ============================================================
# 3. Optimize Pacman Configuration
# ============================================================

echo ""
echo "[3/5] Optimizing pacman configuration..."

PACMAN_CONF="/etc/pacman.conf"
PACMAN_BACKUP="${PACMAN_CONF}.anthonyware.bak"

# Backup original
if [[ ! -f "$PACMAN_BACKUP" ]]; then
  ${SUDO} cp "$PACMAN_CONF" "$PACMAN_BACKUP"
fi

# Enable parallel downloads if not already set
if ! grep -q "^ParallelDownloads" "$PACMAN_CONF"; then
  echo "  • Enabling parallel downloads (5)"
  ${SUDO} sed -i '/^#ParallelDownloads/s/^#//' "$PACMAN_CONF"
  if ! grep -q "^ParallelDownloads" "$PACMAN_CONF"; then
    echo "ParallelDownloads = 5" | ${SUDO} tee -a "$PACMAN_CONF" >/dev/null
  fi
fi

# Enable color output if not already set
if ! grep -q "^Color" "$PACMAN_CONF"; then
  echo "  • Enabling color output"
  ${SUDO} sed -i '/^#Color/s/^#//' "$PACMAN_CONF"
fi

# Enable VerbosePkgLists for detailed package info
if ! grep -q "^VerbosePkgLists" "$PACMAN_CONF"; then
  echo "  • Enabling verbose package lists"
  ${SUDO} sed -i '/^#VerbosePkgLists/s/^#//' "$PACMAN_CONF"
fi

# Set ILoveCandy for Pac-Man progress bars
if ! grep -q "ILoveCandy" "$PACMAN_CONF"; then
  echo "  • Enabling Pac-Man progress bar"
  ${SUDO} sed -i '/^# Misc options/a ILoveCandy' "$PACMAN_CONF"
fi

echo "✓ Pacman configuration optimized"

# ============================================================
# 4. Journal Size Limits
# ============================================================

echo ""
echo "[4/5] Configuring journald limits..."

JOURNALD_CONF="/etc/systemd/journald.conf"
JOURNALD_OVERRIDE="/etc/systemd/journald.conf.d/anthonyware.conf"

${SUDO} mkdir -p "$(dirname "$JOURNALD_OVERRIDE")"

cat <<'EOF' | ${SUDO} tee "$JOURNALD_OVERRIDE" >/dev/null
[Journal]
# Limit journal size to 500MB
SystemMaxUse=500M

# Keep logs for 4 weeks
MaxRetentionSec=4week

# Compress logs older than 1 day
MaxFileSec=1day

# Forward to syslog
ForwardToSyslog=no
EOF

echo "✓ Journald limits configured (500MB max, 4 weeks retention)"

# ============================================================
# 5. Optimize Makepkg for AUR Builds
# ============================================================

echo ""
echo "[5/5] Optimizing makepkg for AUR builds..."

MAKEPKG_CONF="/etc/makepkg.conf"
MAKEPKG_BACKUP="${MAKEPKG_CONF}.anthonyware.bak"

# Backup original
if [[ ! -f "$MAKEPKG_BACKUP" ]]; then
  ${SUDO} cp "$MAKEPKG_CONF" "$MAKEPKG_BACKUP"
fi

# Detect CPU cores
CORES=$(nproc)
MAKEFLAGS="-j$((CORES + 1))"

# Enable parallel compilation
if ! grep -q "^MAKEFLAGS=.*-j" "$MAKEPKG_CONF"; then
  echo "  • Enabling parallel compilation (${MAKEFLAGS})"
  ${SUDO} sed -i "s/^#MAKEFLAGS=.*/MAKEFLAGS=\"${MAKEFLAGS}\"/" "$MAKEPKG_CONF"
  if ! grep -q "^MAKEFLAGS=" "$MAKEPKG_CONF"; then
    echo "MAKEFLAGS=\"${MAKEFLAGS}\"" | ${SUDO} tee -a "$MAKEPKG_CONF" >/dev/null
  fi
fi

# Enable ccache if installed
if command -v ccache >/dev/null 2>&1; then
  if ! grep -q "BUILDENV=.*ccache" "$MAKEPKG_CONF"; then
    echo "  • Enabling ccache for faster recompilation"
    ${SUDO} sed -i 's/!ccache/ccache/' "$MAKEPKG_CONF"
  fi
fi

# Use all CPU cores for compression
if ! grep -q "^COMPRESSZST=.*-T0" "$MAKEPKG_CONF"; then
  echo "  • Optimizing package compression"
  ${SUDO} sed -i "s/^COMPRESSZST=.*/COMPRESSZST=(zstd -c -T0 --ultra -20 -)/" "$MAKEPKG_CONF"
fi

echo "✓ Makepkg optimized for ${CORES} cores"

# ============================================================
# Summary
# ============================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Arch Linux Optimization Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Applied optimizations:"
echo "  • 5 pacman hooks (systemd, GRUB, icons, fonts, cache)"
echo "  • systemd-tmpfiles for clean directory management"
echo "  • Pacman parallel downloads and color output"
echo "  • Journald size limits (500MB)"
echo "  • Makepkg parallel compilation (${CORES} cores)"
echo ""
echo "Changes take effect immediately. No reboot required."
echo ""
