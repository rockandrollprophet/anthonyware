#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Anthonyware OS — Enable Security Hardening
#
#  Activates security frameworks that were disabled during
#  development: firewalld, AppArmor, Firejail profiles
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_PATH="${HOME}/anthonyware"

echo -e "${CYAN}=== Security Hardening Enabler ===${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${YELLOW}⚠${NC} Some operations require root privileges"
   echo "  Run with: sudo $0"
   echo
fi

# ============================================================
#  FIREWALLD
# ============================================================

echo -e "${CYAN}[1/3] Firewalld Configuration${NC}"
echo "───────────────────────────────────"

if systemctl is-active --quiet firewalld; then
    echo -e "${GREEN}✓${NC} Firewalld is already running"
else
    read -rp "Enable firewalld? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        sudo systemctl enable --now firewalld
        echo -e "${GREEN}✓${NC} Firewalld enabled"
    fi
fi

# Deploy custom zone
if [[ -f "$REPO_PATH/configs/firewalld/anthonyware.xml" ]]; then
    read -rp "Deploy custom anthonyware firewall zone? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        sudo cp "$REPO_PATH/configs/firewalld/anthonyware.xml" /etc/firewalld/zones/
        sudo firewall-cmd --reload
        sudo firewall-cmd --set-default-zone=anthonyware
        echo -e "${GREEN}✓${NC} Custom zone deployed and activated"
    fi
fi

echo

# ============================================================
#  APPARMOR
# ============================================================

echo -e "${CYAN}[2/3] AppArmor Profiles${NC}"
echo "───────────────────────────────────"

if command -v aa-status &>/dev/null; then
    echo -e "${GREEN}✓${NC} AppArmor is installed"
    
    # Check if AppArmor is enabled
    if systemctl is-active --quiet apparmor; then
        echo -e "${GREEN}✓${NC} AppArmor service is active"
    else
        read -rp "Enable AppArmor service? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            sudo systemctl enable --now apparmor
            echo -e "${GREEN}✓${NC} AppArmor enabled"
        fi
    fi
    
    # Deploy profiles
    APPARMOR_PROFILES=(
        "usr.bin.zen-browser"
        "usr.bin.dolphin"
    )
    
    echo
    read -rp "Deploy AppArmor profiles? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        for profile in "${APPARMOR_PROFILES[@]}"; do
            if [[ -f "$REPO_PATH/configs/apparmor/$profile" ]]; then
                # Uncomment the profile
                sudo sed -i 's/^# //' "$REPO_PATH/configs/apparmor/$profile" || true
                sudo cp "$REPO_PATH/configs/apparmor/$profile" "/etc/apparmor.d/"
                echo -e "${GREEN}✓${NC} Deployed: $profile"
            fi
        done
        
        sudo systemctl reload apparmor
        echo -e "${GREEN}✓${NC} AppArmor profiles loaded"
    fi
else
    echo -e "${YELLOW}⚠${NC} AppArmor not installed"
    read -rp "Install AppArmor? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        sudo pacman -S --noconfirm apparmor
        echo -e "${GREEN}✓${NC} AppArmor installed"
        echo -e "${YELLOW}⚠${NC} Reboot required to activate AppArmor"
    fi
fi

echo

# ============================================================
#  FIREJAIL
# ============================================================

echo -e "${CYAN}[3/3] Firejail Sandboxing${NC}"
echo "───────────────────────────────────"

if command -v firejail &>/dev/null; then
    echo -e "${GREEN}✓${NC} Firejail is installed"
    
    FIREJAIL_PROFILES=(
        "zen-browser.profile"
        "dolphin.profile"
    )
    
    read -rp "Deploy Firejail profiles? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        mkdir -p "$HOME/.config/firejail"
        
        for profile in "${FIREJAIL_PROFILES[@]}"; do
            if [[ -f "$REPO_PATH/configs/firejail/$profile" ]]; then
                # Uncomment the profile
                sed 's/^# //' "$REPO_PATH/configs/firejail/$profile" > "$HOME/.config/firejail/$profile"
                echo -e "${GREEN}✓${NC} Deployed: $profile"
            fi
        done
        
        echo -e "${GREEN}✓${NC} Firejail profiles deployed"
        echo
        echo "To use Firejail, run applications with:"
        echo "  firejail zen-browser"
        echo "  firejail dolphin"
    fi
else
    echo -e "${YELLOW}⚠${NC} Firejail not installed"
    read -rp "Install Firejail? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        sudo pacman -S --noconfirm firejail
        echo -e "${GREEN}✓${NC} Firejail installed"
    fi
fi

echo

# ============================================================
#  ADDITIONAL HARDENING
# ============================================================

echo -e "${CYAN}Additional Security Hardening${NC}"
echo "───────────────────────────────────"
echo

read -rp "Enable automatic security updates? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    # Create systemd timer for automatic updates
    sudo tee /etc/systemd/system/auto-update.timer >/dev/null <<'EOF'
[Unit]
Description=Automatic System Update Timer

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

    sudo tee /etc/systemd/system/auto-update.service >/dev/null <<'EOF'
[Unit]
Description=Automatic System Update

[Service]
Type=oneshot
ExecStart=/usr/bin/pacman -Syu --noconfirm
EOF

    sudo systemctl enable --now auto-update.timer
    echo -e "${GREEN}✓${NC} Automatic weekly updates enabled"
fi

read -rp "Disable root SSH login? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    if [[ -f /etc/ssh/sshd_config ]]; then
        sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        sudo systemctl reload sshd || true
        echo -e "${GREEN}✓${NC} Root SSH login disabled"
    else
        echo -e "${YELLOW}⚠${NC} SSH not configured"
    fi
fi

read -rp "Enable audit logging? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    if ! command -v auditd &>/dev/null; then
        sudo pacman -S --noconfirm audit
    fi
    sudo systemctl enable --now auditd
    echo -e "${GREEN}✓${NC} Audit logging enabled"
fi

echo

# ============================================================
#  SUMMARY
# ============================================================

echo -e "${GREEN}=== Security Hardening Complete ===${NC}"
echo
echo "Enabled features:"
echo "  • Firewall: $(systemctl is-active firewalld 2>/dev/null || echo 'disabled')"
echo "  • AppArmor: $(systemctl is-active apparmor 2>/dev/null || echo 'disabled')"
echo "  • Firejail: $(command -v firejail &>/dev/null && echo 'installed' || echo 'not installed')"
echo "  • Audit: $(systemctl is-active auditd 2>/dev/null || echo 'disabled')"
echo
echo "Next steps:"
echo "  • Review firewall rules: sudo firewall-cmd --list-all"
echo "  • Check AppArmor status: sudo aa-status"
echo "  • Test sandboxed apps: firejail zen-browser"
echo "  • Review audit logs: sudo ausearch -m avc"
echo
