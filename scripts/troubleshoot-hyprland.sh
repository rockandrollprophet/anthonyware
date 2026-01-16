#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Anthonyware OS — Hyprland Troubleshooter
#
#  Diagnoses and fixes common Hyprland/Wayland issues
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Hyprland Troubleshooter ===${NC}"
echo

# Check if running in Hyprland
echo -e "${CYAN}[1/6] Checking Hyprland Session${NC}"
echo "───────────────────────────────────"

if [[ "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo -e "${GREEN}✓${NC} Running in Hyprland session"
    echo "  Signature: $HYPRLAND_INSTANCE_SIGNATURE"
else
    echo -e "${RED}✗${NC} Not running in Hyprland"
    echo "  This script is most useful when run inside Hyprland"
fi

if [[ "${WAYLAND_DISPLAY:-}" ]]; then
    echo -e "${GREEN}✓${NC} Wayland display: $WAYLAND_DISPLAY"
else
    echo -e "${RED}✗${NC} WAYLAND_DISPLAY not set"
fi

echo

# Check Hyprland binary
echo -e "${CYAN}[2/6] Checking Hyprland Installation${NC}"
echo "───────────────────────────────────"

if command -v Hyprland &>/dev/null; then
    echo -e "${GREEN}✓${NC} Hyprland binary found"
    HYPR_VERSION=$(Hyprland --version 2>/dev/null | head -1 || echo "unknown")
    echo "  Version: $HYPR_VERSION"
else
    echo -e "${RED}✗${NC} Hyprland binary not found"
fi

echo

# Check config file
echo -e "${CYAN}[3/6] Checking Configuration${NC}"
echo "───────────────────────────────────"

HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"
if [[ -f "$HYPR_CONFIG" ]]; then
    echo -e "${GREEN}✓${NC} Config file exists: $HYPR_CONFIG"
    
    # Check for syntax errors
    if bash -n "$HYPR_CONFIG" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Config syntax appears valid"
    else
        echo -e "${YELLOW}⚠${NC} Config may have syntax issues"
    fi
else
    echo -e "${RED}✗${NC} Config file not found: $HYPR_CONFIG"
fi

# Check other configs
CONFIGS=(
    "$HOME/.config/waybar/config.jsonc"
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.config/hypr/hyprlock.conf"
    "$HOME/.config/hypr/hyprpaper.conf"
)

for cfg in "${CONFIGS[@]}"; do
    if [[ -f "$cfg" ]]; then
        echo -e "${GREEN}✓${NC} Found: $(basename "$cfg")"
    else
        echo -e "${YELLOW}⚠${NC} Missing: $cfg"
    fi
done

echo

# Check essential dependencies
echo -e "${CYAN}[4/6] Checking Dependencies${NC}"
echo "───────────────────────────────────"

DEPS=(
    "waybar:waybar"
    "kitty:kitty"
    "wofi:wofi"
    "mako:mako"
    "grim:grim"
    "slurp:slurp"
    "wl-clipboard:wl-copy"
)

for dep in "${DEPS[@]}"; do
    name="${dep%%:*}"
    cmd="${dep##*:}"
    
    if command -v "$cmd" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $name installed"
    else
        echo -e "${RED}✗${NC} $name NOT installed"
    fi
done

echo

# Check portals
echo -e "${CYAN}[5/6] Checking XDG Portals${NC}"
echo "───────────────────────────────────"

PORTALS=(
    "/usr/lib/xdg-desktop-portal-hyprland"
    "/usr/lib/xdg-desktop-portal-gtk"
    "/usr/lib/xdg-desktop-portal"
)

for portal in "${PORTALS[@]}"; do
    if [[ -f "$portal" ]]; then
        echo -e "${GREEN}✓${NC} Found: $(basename "$portal")"
    else
        echo -e "${YELLOW}⚠${NC} Missing: $(basename "$portal")"
    fi
done

# Check if portal is running
if pgrep -x "xdg-desktop-portal-hyprland" &>/dev/null; then
    echo -e "${GREEN}✓${NC} xdg-desktop-portal-hyprland is running"
else
    echo -e "${YELLOW}⚠${NC} xdg-desktop-portal-hyprland not running"
fi

echo

# Check logs for errors
echo -e "${CYAN}[6/6] Checking Recent Logs${NC}"
echo "───────────────────────────────────"

HYPR_LOG="$HOME/.hyprland.log"
if [[ -f "$HYPR_LOG" ]]; then
    ERROR_COUNT=$(grep -ic "error" "$HYPR_LOG" 2>/dev/null || echo "0")
    WARN_COUNT=$(grep -ic "warn" "$HYPR_LOG" 2>/dev/null || echo "0")
    
    echo -e "${GREEN}✓${NC} Log file found: $HYPR_LOG"
    echo "  Errors: $ERROR_COUNT | Warnings: $WARN_COUNT"
    
    if [[ "$ERROR_COUNT" -gt 0 ]]; then
        echo
        echo "Recent errors:"
        grep -i "error" "$HYPR_LOG" | tail -5 || true
    fi
else
    echo -e "${YELLOW}⚠${NC} Log file not found: $HYPR_LOG"
fi

echo

# Repair options
echo -e "${CYAN}Repair Options${NC}"
echo "───────────────────────────────────"
echo

read -rp "Reload Hyprland config? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    if command -v hyprctl &>/dev/null; then
        hyprctl reload
        echo -e "${GREEN}✓${NC} Config reloaded"
    else
        echo -e "${RED}✗${NC} hyprctl not found"
    fi
fi

read -rp "Restart Waybar? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    killall waybar 2>/dev/null || true
    sleep 1
    waybar &>/dev/null &
    disown
    echo -e "${GREEN}✓${NC} Waybar restarted"
fi

read -rp "Restart notification daemon? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    killall mako 2>/dev/null || true
    killall swaync 2>/dev/null || true
    sleep 1
    if command -v swaync &>/dev/null; then
        swaync &>/dev/null &
        disown
        echo -e "${GREEN}✓${NC} SwayNC started"
    else
        mako &>/dev/null &
        disown
        echo -e "${GREEN}✓${NC} Mako started"
    fi
fi

read -rp "Reset Hyprland to default config? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    if [[ -f "$HOME/anthonyware/configs/hypr/hyprland.conf" ]]; then
        cp "$HOME/anthonyware/configs/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
        echo -e "${GREEN}✓${NC} Config reset from repository"
    else
        echo -e "${RED}✗${NC} Default config not found in repository"
    fi
fi

read -rp "View full Hyprland log? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    less "$HYPR_LOG"
fi

echo
echo -e "${GREEN}=== Hyprland Troubleshooting Complete ===${NC}"
echo
echo "Additional commands:"
echo "  • Reload config:      hyprctl reload"
echo "  • List monitors:      hyprctl monitors"
echo "  • List windows:       hyprctl clients"
echo "  • Check dispatch:     hyprctl dispatch exec kitty"
echo "  • View log:           tail -f ~/.hyprland.log"
echo "  • Kill Hyprland:      killall Hyprland"
