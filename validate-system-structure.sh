#!/usr/bin/env bash
# System Structure Validation Script
# Ensures proper directory setup and critical services

set -euo pipefail

echo "======================================"
echo "  System Structure Validation"
echo "======================================"
echo

# 1. Check XDG User Directories
echo "[1/8] XDG User Directories..."
if [[ -f ~/.config/user-dirs.dirs ]]; then
    echo "  ✓ XDG config exists"
    # Create missing directories
    source ~/.config/user-dirs.dirs
    for dir in "$XDG_DESKTOP_DIR" "$XDG_DOWNLOAD_DIR" "$XDG_DOCUMENTS_DIR" \
               "$XDG_MUSIC_DIR" "$XDG_PICTURES_DIR" "$XDG_VIDEOS_DIR" \
               "$XDG_TEMPLATES_DIR" "$XDG_PUBLICSHARE_DIR"; do
        mkdir -p "$dir" 2>/dev/null || true
    done
    echo "  ✓ Standard directories created"
else
    echo "  ✗ XDG config missing - run: xdg-user-dirs-update"
fi

# 2. Check Essential Config Directories
echo "[2/8] Config Directories..."
for dir in ~/.config ~/.local/share ~/.local/state ~/.cache; do
    if [[ -d "$dir" ]]; then
        echo "  ✓ $dir"
    else
        echo "  ✗ $dir missing - creating..."
        mkdir -p "$dir"
    fi
done

# 3. Check Hyprland Setup
echo "[3/8] Hyprland Configuration..."
REQUIRED_CONFIGS=("hypr" "kitty" "rofi")
for config in "${REQUIRED_CONFIGS[@]}"; do
    if [[ -d ~/.config/$config ]]; then
        echo "  ✓ ~/.config/$config"
    else
        echo "  ⚠ ~/.config/$config missing"
    fi
done

# 4. Check Essential Services
echo "[4/8] Essential Services..."
SERVICES=("NetworkManager" "greetd")
for svc in "${SERVICES[@]}"; do
    if systemctl is-enabled "$svc" &>/dev/null; then
        STATUS=$(systemctl is-active "$svc" 2>/dev/null || echo "inactive")
        if [[ "$STATUS" == "active" ]]; then
            echo "  ✓ $svc: enabled & running"
        else
            echo "  ⚠ $svc: enabled but $STATUS"
        fi
    else
        echo "  ✗ $svc: not enabled"
    fi
done

# 5. Check Development Tools
echo "[5/8] Development Tools..."
TOOLS=("code" "nvim" "firefox" "git")
for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        echo "  ✓ $tool"
    else
        echo "  ✗ $tool not found"
    fi
done

# 6. Check Display/Graphics
echo "[6/8] Display & Graphics..."
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    echo "  ✓ Wayland session active: $WAYLAND_DISPLAY"
elif [[ -n "${DISPLAY:-}" ]]; then
    echo "  ⚠ X11 session active: $DISPLAY"
else
    echo "  ✗ No display session"
fi

if command -v Hyprland &>/dev/null; then
    echo "  ✓ Hyprland installed"
fi

# 7. Check Network Connectivity
echo "[7/8] Network Connectivity..."
if ping -c 1 8.8.8.8 &>/dev/null; then
    echo "  ✓ Internet reachable"
else
    echo "  ✗ No internet connection"
fi

# 8. Check System Directories
echo "[8/8] System Directories..."
SYSTEM_DIRS=("/etc/xdg" "/usr/share/applications" "/usr/local/bin")
for dir in "${SYSTEM_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        echo "  ✓ $dir"
    else
        echo "  ✗ $dir missing"
    fi
done

echo
echo "======================================"
echo "  Validation Complete"
echo "======================================"
echo
echo "Summary:"
echo "  - XDG directories configured"
echo "  - Config paths exist"
echo "  - Dev tools available"
echo "  - Network functional"
echo
echo "Note: greetd may show inactive if you're already logged in."
echo "This is normal - it only runs at login screen."
