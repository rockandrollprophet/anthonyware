#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Anthonyware OS — Audio Troubleshooter
#
#  Diagnoses and fixes common PipeWire/WirePlumber audio issues
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Audio Troubleshooter ===${NC}"
echo

# Check if audio services are running
echo -e "${CYAN}[1/6] Checking Audio Services${NC}"
echo "───────────────────────────────────"

check_service() {
    local service="$1"
    if systemctl --user is-active --quiet "$service" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $service is running"
        return 0
    else
        echo -e "${RED}✗${NC} $service is NOT running"
        return 1
    fi
}

SERVICES_OK=true
check_service pipewire || SERVICES_OK=false
check_service pipewire-pulse || SERVICES_OK=false
check_service wireplumber || SERVICES_OK=false

echo

# Check for audio devices
echo -e "${CYAN}[2/6] Detecting Audio Devices${NC}"
echo "───────────────────────────────────"

if command -v pactl &>/dev/null; then
    SINKS=$(pactl list short sinks 2>/dev/null)
    SOURCES=$(pactl list short sources 2>/dev/null)
    
    if [[ -n "$SINKS" ]]; then
        echo -e "${GREEN}✓${NC} Audio output devices found:"
        echo "$SINKS" | while read -r line; do
            echo "  • $line"
        done
    else
        echo -e "${RED}✗${NC} No audio output devices detected"
    fi
    
    echo
    
    if [[ -n "$SOURCES" ]]; then
        echo -e "${GREEN}✓${NC} Audio input devices found:"
        echo "$SOURCES" | while read -r line; do
            echo "  • $line"
        done
    else
        echo -e "${YELLOW}⚠${NC} No audio input devices detected"
    fi
else
    echo -e "${RED}✗${NC} pactl not found (install pipewire-pulse)"
fi

echo

# Check for audio modules
echo -e "${CYAN}[3/6] Checking Kernel Audio Modules${NC}"
echo "───────────────────────────────────"

MODULES=(snd_hda_intel snd_hda_codec snd_pcm snd_timer)
MODULES_OK=true

for mod in "${MODULES[@]}"; do
    if lsmod | grep -q "^$mod"; then
        echo -e "${GREEN}✓${NC} $mod loaded"
    else
        echo -e "${RED}✗${NC} $mod NOT loaded"
        MODULES_OK=false
    fi
done

echo

# Check mixer levels
echo -e "${CYAN}[4/6] Checking Mixer Levels${NC}"
echo "───────────────────────────────────"

if command -v amixer &>/dev/null; then
    MUTED=$(amixer get Master 2>/dev/null | grep -o '\[off\]' || true)
    if [[ -n "$MUTED" ]]; then
        echo -e "${YELLOW}⚠${NC} Master volume is MUTED"
    else
        VOL=$(amixer get Master 2>/dev/null | grep -oP '\[\d+%\]' | head -1 || echo "[unknown]")
        echo -e "${GREEN}✓${NC} Master volume: $VOL"
    fi
else
    echo -e "${YELLOW}⚠${NC} amixer not found (install alsa-utils)"
fi

echo

# Check config files
echo -e "${CYAN}[5/6] Checking Configuration Files${NC}"
echo "───────────────────────────────────"

CONFIG_FILES=(
    "$HOME/.config/pipewire/pipewire.conf"
    "$HOME/.config/wireplumber/main.lua.d/50-alsa-config.lua"
    "/etc/pipewire/pipewire.conf"
)

for cfg in "${CONFIG_FILES[@]}"; do
    if [[ -f "$cfg" ]]; then
        echo -e "${GREEN}✓${NC} Found: $cfg"
    else
        echo -e "${YELLOW}⚠${NC} Missing: $cfg (using defaults)"
    fi
done

echo

# Repair options
echo -e "${CYAN}[6/6] Repair Options${NC}"
echo "───────────────────────────────────"
echo

if [[ "$SERVICES_OK" == false ]]; then
    read -rp "Restart PipeWire services? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        echo "Restarting audio services..."
        systemctl --user restart pipewire pipewire-pulse wireplumber
        sleep 2
        echo -e "${GREEN}✓${NC} Services restarted"
    fi
fi

if [[ "$MODULES_OK" == false ]]; then
    read -rp "Reload audio kernel modules? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        echo "Reloading kernel modules..."
        sudo modprobe -r snd_hda_intel snd_hda_codec || true
        sudo modprobe snd_hda_intel snd_hda_codec
        echo -e "${GREEN}✓${NC} Modules reloaded"
    fi
fi

read -rp "Unmute and set volume to 75%? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    amixer set Master unmute 2>/dev/null || true
    amixer set Master 75% 2>/dev/null || true
    pactl set-sink-volume @DEFAULT_SINK@ 75% 2>/dev/null || true
    pactl set-sink-mute @DEFAULT_SINK@ 0 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Volume set to 75%, unmuted"
fi

read -rp "Open pavucontrol (GUI mixer)? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    pavucontrol &>/dev/null &
    disown
    echo -e "${GREEN}✓${NC} Launched pavucontrol"
fi

echo
echo -e "${GREEN}=== Audio Troubleshooting Complete ===${NC}"
echo
echo "Additional commands:"
echo "  • Test sound:         speaker-test -t wav -c 2"
echo "  • List devices:       pactl list sinks"
echo "  • Show wireplumber:   wpctl status"
echo "  • Audio logs:         journalctl --user -u pipewire -n 50"
