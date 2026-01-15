#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  first-boot-wizard.sh
#  First-boot setup wizard for Anthonyware OS
# ============================================================

echo "╔════════════════════════════════════════╗"
echo "║ Anthonyware OS — First Boot Wizard     ║"
echo "╚════════════════════════════════════════╝"
echo

# ============================================================
#  Change Password
# ============================================================
read -rp "1. Change your login password now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  echo "Changing password..."
  passwd
  echo "✓ Password changed"
fi
echo

# ============================================================
#  SSH Setup
# ============================================================
read -rp "2. Set up SSH authorized_keys? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  echo "Edit authorized_keys in your editor..."
  ${EDITOR:-nano} ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  echo "✓ SSH configured"
fi
echo

# ============================================================
#  Git Configuration
# ============================================================
read -rp "3. Configure git? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  read -rp "  Git user.name: " gitname
  read -rp "  Git user.email: " gitemail
  git config --global user.name "$gitname"
  git config --global user.email "$gitemail"
  echo "✓ Git configured"
fi
echo

# ============================================================
#  System Check
# ============================================================
read -rp "4. Run system health check now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  health-dashboard || true
fi
echo

# ============================================================
#  Backup Baseline
# ============================================================
read -rp "5. Create baseline system snapshot? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  echo "Creating baseline snapshot..."
  if command -v timeshift >/dev/null 2>&1; then
    sudo timeshift --create --comments "Anthonyware baseline" --tags D || true
    echo "✓ Snapshot created"
  else
    echo "✗ Timeshift not installed"
  fi
fi
echo

# ============================================================
#  Welcome Screen
# ============================================================
read -rp "6. Show welcome screen? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  scripts/welcome.sh || true
fi
echo

echo "═════════════════════════════════════════"
echo "✓ First Boot Wizard Complete"
echo "═════════════════════════════════════════"
echo
echo "📚 Next: Read docs/first-boot-checklist.md"
echo "🎯 Or:   Customize ~/.config/hypr/hyprland.conf"
