#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Anthonyware OS — First Boot Wizard
#
#  Run this script after first login to:
#    - Validate installation
#    - Test critical services
#    - Confirm system configuration
#    - Enable optional features
#    - Run health checks
# ============================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REPO_PATH="${HOME}/anthonyware"

# ============================================================
#  HEADER
# ============================================================

clear
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════╗
║                                                      ║
║         Anthonyware OS — First Boot Wizard          ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo
echo "Welcome to Anthonyware OS!"
echo
echo "This wizard will help you:"
echo "  • Validate your installation"
echo "  • Test critical services"
echo "  • Enable optional features"
echo "  • Run system health checks"
echo
read -rp "Press Enter to begin..."

# ============================================================
#  SYSTEM INFO
# ============================================================

echo
echo -e "${CYAN}[1/8] System Information${NC}"
echo "═══════════════════════════════════════════════════════"
echo

echo "Hostname:     $(hostname)"
echo "Username:     $USER"
echo "Kernel:       $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Uptime:       $(uptime -p)"
echo

# ============================================================
#  SUDO TEST
# ============================================================

echo -e "${CYAN}[2/8] Testing Sudo Access${NC}"
echo "═══════════════════════════════════════════════════════"
echo

if sudo -v; then
  echo -e "${GREEN}✓${NC} Sudo access confirmed (password required)"
else
  echo -e "${RED}✗${NC} Sudo access failed"
  echo "You may need to add your user to the wheel group."
  exit 1
fi

echo

# ============================================================
#  SERVICE STATUS
# ============================================================

echo -e "${CYAN}[3/8] Checking Critical Services${NC}"
echo "═══════════════════════════════════════════════════════"
echo

check_service() {
  local service="$1"
  if systemctl is-active --quiet "$service"; then
    echo -e "${GREEN}✓${NC} $service is running"
  else
    echo -e "${YELLOW}⚠${NC} $service is not running"
  fi
}

check_service NetworkManager
check_service systemd-resolved

# Optional services (may not be enabled yet)
systemctl is-active --quiet sddm && echo -e "${GREEN}✓${NC} SDDM (display manager)" || echo -e "${YELLOW}⚠${NC} SDDM not enabled (login manager)"
systemctl is-active --quiet firewalld && echo -e "${GREEN}✓${NC} Firewalld (firewall)" || echo -e "${YELLOW}⚠${NC} Firewalld not enabled"

echo

# ============================================================
#  HYPRLAND CHECK
# ============================================================

echo -e "${CYAN}[4/8] Checking Hyprland Installation${NC}"
echo "═══════════════════════════════════════════════════════"
echo

if command -v Hyprland &>/dev/null; then
  echo -e "${GREEN}✓${NC} Hyprland is installed"
  HYPR_VERSION=$(Hyprland --version 2>/dev/null | head -n1 || echo "unknown")
  echo "  Version: $HYPR_VERSION"
else
  echo -e "${RED}✗${NC} Hyprland not found"
  echo "  You may need to install it manually or run the installer pipeline."
fi

echo

# ============================================================
#  GPU CHECK
# ============================================================

echo -e "${CYAN}[5/8] GPU Detection${NC}"
echo "═══════════════════════════════════════════════════════"
echo

if command -v lspci &>/dev/null; then
  GPUS=$(lspci | grep -i 'vga\|3d\|display')
  if [[ -n "$GPUS" ]]; then
    echo -e "${GREEN}✓${NC} GPU(s) detected:"
    echo "$GPUS" | while read -r line; do
      echo "  • $line"
    done
  else
    echo -e "${YELLOW}⚠${NC} No GPU detected"
  fi
else
  echo -e "${YELLOW}⚠${NC} lspci not available"
fi

echo

# ============================================================
#  VALIDATION SCRIPT
# ============================================================

echo -e "${CYAN}[6/8] Running System Validation${NC}"
echo "═══════════════════════════════════════════════════════"
echo

if [[ -f "$REPO_PATH/install/24-cleanup-and-verify.sh" ]]; then
  echo "Running validation script..."
  echo
  bash "$REPO_PATH/install/24-cleanup-and-verify.sh" || true
else
  echo -e "${YELLOW}⚠${NC} Validation script not found at:"
  echo "  $REPO_PATH/install/24-cleanup-and-verify.sh"
fi

echo

# ============================================================
#  PERSONAL CONFIGURATION
# ============================================================

echo -e "${CYAN}[7/8] Personal Configuration${NC}"
echo "═══════════════════════════════════════════════════════"
echo

# Change Password
read -rp "Change your login password now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  echo "Changing password..."
  passwd
  echo -e "${GREEN}✓${NC} Password changed"
fi
echo

# SSH Setup
read -rp "Set up SSH authorized_keys? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  echo "Edit authorized_keys in your editor..."
  ${EDITOR:-nano} ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  echo -e "${GREEN}✓${NC} SSH configured"
fi
echo

# Git Configuration
read -rp "Configure git? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  read -rp "  Git user.name: " gitname
  read -rp "  Git user.email: " gitemail
  git config --global user.name "$gitname"
  git config --global user.email "$gitemail"
  echo -e "${GREEN}✓${NC} Git configured"
fi
echo

# ============================================================
#  OPTIONAL FEATURES
# ============================================================

echo -e "${CYAN}[8/8] Optional Features${NC}"
echo "═══════════════════════════════════════════════════════"
echo

echo "Would you like to enable any of these features?"
echo

# Display Manager (SDDM)
if ! systemctl is-enabled --quiet sddm 2>/dev/null; then
  read -rp "Enable SDDM display manager? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    if [[ -f "$REPO_PATH/scripts/enable-sddm.sh" ]]; then
      sudo bash "$REPO_PATH/scripts/enable-sddm.sh"
      echo -e "${GREEN}✓${NC} SDDM enabled"
    else
      sudo systemctl enable sddm
      echo -e "${GREEN}✓${NC} SDDM enabled"
    fi
  fi
fi

# Plymouth Boot Splash
if ! systemctl is-enabled --quiet plymouth-start 2>/dev/null; then
  read -rp "Enable Plymouth boot splash? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    if [[ -f "$REPO_PATH/scripts/enable-plymouth.sh" ]]; then
      sudo bash "$REPO_PATH/scripts/enable-plymouth.sh"
      echo -e "${GREEN}✓${NC} Plymouth enabled"
    else
      echo -e "${YELLOW}⚠${NC} Plymouth enable script not found"
    fi
  fi
fi

# Firewall
if ! systemctl is-enabled --quiet firewalld 2>/dev/null; then
  read -rp "Enable Firewalld? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    sudo systemctl enable --now firewalld
    echo -e "${GREEN}✓${NC} Firewalld enabled"
  fi
fi

# Visualizer (eww + cava)
read -rp "Enable desktop visualizer (eww + cava)? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  if [[ -f "$REPO_PATH/scripts/enable-visualizer.sh" ]]; then
    bash "$REPO_PATH/scripts/enable-visualizer.sh"
    echo -e "${GREEN}✓${NC} Visualizer enabled"
  else
    echo -e "${YELLOW}⚠${NC} Visualizer enable script not found"
  fi
fi

# System Health Check
read -rp "Run system health check now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  if [[ -f "$REPO_PATH/scripts/health-dashboard.sh" ]]; then
    bash "$REPO_PATH/scripts/health-dashboard.sh" || true
  else
    echo -e "${YELLOW}⚠${NC} Health dashboard script not found"
  fi
fi

# Baseline Snapshot
read -rp "Create baseline system snapshot? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  echo "Creating baseline snapshot..."
  if command -v timeshift >/dev/null 2>&1; then
    sudo timeshift --create --comments "Anthonyware baseline" --tags D || true
    echo -e "${GREEN}✓${NC} Snapshot created"
  else
    echo -e "${YELLOW}⚠${NC} Timeshift not installed"
  fi
fi

echo

# ============================================================
#  COMPLETION
# ============================================================

echo
echo -e "${GREEN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════╗
║                                                      ║
║            First Boot Setup Complete! ✓             ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo

echo "Your Anthonyware OS installation is ready!"
echo
echo "Next Steps:"
echo "  • Reboot to apply all changes: sudo reboot"
echo "  • Login to Hyprland from SDDM"
echo "  • Run health check: ~/anthonyware/scripts/health-dashboard.sh"
echo "  • Explore documentation in ~/anthonyware/docs/"
echo

echo "Useful Commands:"
echo "  • Update system:    ~/anthonyware/scripts/update-everything.sh"
echo "  • System backup:    ~/anthonyware/scripts/backup-system.sh"
echo "  • Maintenance:      ~/anthonyware/scripts/maintenance.sh"
echo

read -rp "Reboot now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  echo "Rebooting in 3 seconds..."
  sleep 3
  sudo reboot
else
  echo "Ready to reboot when you are. Run: sudo reboot"
fi
