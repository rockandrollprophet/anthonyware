#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Anthonyware OS — Network Troubleshooter
#
#  Diagnoses and fixes common network connectivity issues
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Network Troubleshooter ===${NC}"
echo

# Check NetworkManager service
echo -e "${CYAN}[1/7] Checking NetworkManager${NC}"
echo "───────────────────────────────────"

if systemctl is-active --quiet NetworkManager; then
    echo -e "${GREEN}✓${NC} NetworkManager is running"
    NM_OK=true
else
    echo -e "${RED}✗${NC} NetworkManager is NOT running"
    NM_OK=false
fi

echo

# Check network interfaces
echo -e "${CYAN}[2/7] Network Interfaces${NC}"
echo "───────────────────────────────────"

if command -v ip &>/dev/null; then
    INTERFACES=$(ip -br link show | grep -v "^lo" || true)
    if [[ -n "$INTERFACES" ]]; then
        echo "$INTERFACES" | while read -r iface status mac; do
            if [[ "$status" == "UP" ]]; then
                echo -e "${GREEN}✓${NC} $iface: $status ($mac)"
            else
                echo -e "${YELLOW}⚠${NC} $iface: $status ($mac)"
            fi
        done
    else
        echo -e "${RED}✗${NC} No network interfaces found"
    fi
else
    echo -e "${RED}✗${NC} ip command not found"
fi

echo

# Check IP addresses
echo -e "${CYAN}[3/7] IP Addresses${NC}"
echo "───────────────────────────────────"

ADDRESSES=$(ip -br addr show | grep -v "^lo" || true)
if [[ -n "$ADDRESSES" ]]; then
    echo "$ADDRESSES" | while read -r iface status addr rest; do
        if [[ "$addr" != "" ]]; then
            echo -e "${GREEN}✓${NC} $iface: $addr"
        else
            echo -e "${YELLOW}⚠${NC} $iface: No IP address"
        fi
    done
else
    echo -e "${RED}✗${NC} No IP addresses assigned"
fi

echo

# Check default route
echo -e "${CYAN}[4/7] Default Gateway${NC}"
echo "───────────────────────────────────"

GATEWAY=$(ip route show default 2>/dev/null | awk '{print $3}' | head -1 || true)
if [[ -n "$GATEWAY" ]]; then
    echo -e "${GREEN}✓${NC} Default gateway: $GATEWAY"
    
    # Ping gateway
    if ping -c 1 -W 2 "$GATEWAY" &>/dev/null; then
        echo -e "${GREEN}✓${NC} Gateway is reachable"
    else
        echo -e "${RED}✗${NC} Cannot ping gateway"
    fi
else
    echo -e "${RED}✗${NC} No default gateway configured"
fi

echo

# Check DNS
echo -e "${CYAN}[5/7] DNS Resolution${NC}"
echo "───────────────────────────────────"

if [[ -f /etc/resolv.conf ]]; then
    DNS_SERVERS=$(grep "^nameserver" /etc/resolv.conf | awk '{print $2}' || true)
    if [[ -n "$DNS_SERVERS" ]]; then
        echo -e "${GREEN}✓${NC} DNS servers configured:"
        echo "$DNS_SERVERS" | while read -r dns; do
            echo "  • $dns"
        done
    else
        echo -e "${RED}✗${NC} No DNS servers in /etc/resolv.conf"
    fi
else
    echo -e "${RED}✗${NC} /etc/resolv.conf not found"
fi

# Test DNS resolution
echo
if host archlinux.org &>/dev/null; then
    echo -e "${GREEN}✓${NC} DNS resolution working (archlinux.org)"
else
    echo -e "${RED}✗${NC} DNS resolution failed"
fi

echo

# Check internet connectivity
echo -e "${CYAN}[6/7] Internet Connectivity${NC}"
echo "───────────────────────────────────"

if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
    echo -e "${GREEN}✓${NC} Can reach internet (8.8.8.8)"
else
    echo -e "${RED}✗${NC} Cannot reach internet"
fi

if curl -s --max-time 5 https://archlinux.org &>/dev/null; then
    echo -e "${GREEN}✓${NC} HTTPS connectivity working"
else
    echo -e "${RED}✗${NC} HTTPS connectivity failed"
fi

echo

# Check firewall
echo -e "${CYAN}[7/7] Firewall Status${NC}"
echo "───────────────────────────────────"

if systemctl is-active --quiet firewalld 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Firewalld is active"
    ZONE=$(firewall-cmd --get-default-zone 2>/dev/null || echo "unknown")
    echo "  Default zone: $ZONE"
else
    echo -e "${YELLOW}⚠${NC} Firewalld is not active"
fi

echo

# Repair options
echo -e "${CYAN}Repair Options${NC}"
echo "───────────────────────────────────"
echo

if [[ "$NM_OK" == false ]]; then
    read -rp "Start NetworkManager? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        sudo systemctl start NetworkManager
        echo -e "${GREEN}✓${NC} NetworkManager started"
    fi
fi

read -rp "Restart NetworkManager? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    sudo systemctl restart NetworkManager
    sleep 2
    echo -e "${GREEN}✓${NC} NetworkManager restarted"
fi

read -rp "Flush DNS cache? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    sudo resolvectl flush-caches 2>/dev/null || true
    sudo systemctl restart systemd-resolved 2>/dev/null || true
    echo -e "${GREEN}✓${NC} DNS cache flushed"
fi

read -rp "Reset network interfaces? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    echo "Resetting network..."
    sudo ip link set dev $(ip -br link | grep -v "^lo" | head -1 | awk '{print $1}') down
    sleep 1
    sudo ip link set dev $(ip -br link | grep -v "^lo" | head -1 | awk '{print $1}') up
    echo -e "${GREEN}✓${NC} Network interface reset"
fi

read -rp "Connect to WiFi? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    if command -v nmtui &>/dev/null; then
        nmtui
    else
        echo "nmtui not found. Use: nmcli device wifi connect <SSID> password <PASSWORD>"
    fi
fi

echo
echo -e "${GREEN}=== Network Troubleshooting Complete ===${NC}"
echo
echo "Additional commands:"
echo "  • WiFi scan:          nmcli device wifi list"
echo "  • Connect WiFi:       nmcli device wifi connect SSID password PASSWORD"
echo "  • Network status:     nmcli general status"
echo "  • Show connections:   nmcli connection show"
echo "  • Ping test:          ping -c 4 archlinux.org"
echo "  • DNS test:           nslookup archlinux.org"
