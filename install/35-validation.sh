#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

# ============================================================
#  35-validation.sh
#  Comprehensive validation of all installed components
#  Checks: configs, services, GPU, Python, tools, etc.
# ============================================================

echo "=============================================="
echo " Anthonyware OS — Validation Phase"
echo "=============================================="

TARGET_USER="${TARGET_USER:-${SUDO_USER:-}}"
if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
  echo "WARNING: TARGET_USER not set or is root. Skipping user-specific validations." >&2
  TARGET_USER=""
  TARGET_HOME=""
elif ! TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)" || [[ ! -d "$TARGET_HOME" ]]; then
  echo "WARNING: User $TARGET_USER or home directory not found. Skipping user-specific validations." >&2
  TARGET_USER=""
  TARGET_HOME=""
fi

log() { echo "[validation] $*"; }
err() { echo "[validation] ERROR: $*" >&2; }

ERRORS=0
WARNINGS=0
FAILED_CMDS=()
FAILED_FILES=()

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    log "✓ File: $path"
  else
    err "✗ Missing file: $path"
    FAILED_FILES+=("$path")
    ((ERRORS++))
  fi
}

check_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    log "✓ Directory: $path"
  else
    err "✗ Missing directory: $path"
    ((ERRORS++))
  fi
}

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    log "✓ Command: $cmd"
  else
    err "✗ Missing command: $cmd"
    FAILED_CMDS+=("$cmd")
    ((ERRORS++))
  fi
}

check_service() {
  local svc="$1"
  if systemctl is-active --quiet "$svc" 2>/dev/null; then
    log "✓ Service active: $svc"
  else
    log "⊙ Service not active: $svc (may be on-demand)"
    ((WARNINGS++))
  fi
}

# ============================================================
#  SECTION 1: Qt6 / SDDM
# ============================================================
log "=== Qt6 / SDDM ==="
check_file "/etc/sddm.conf.d/10-qt6-env.conf"
check_cmd "sddm"

# ============================================================
#  SECTION 2: Hyprland Desktop
# ============================================================
log "=== Hyprland Desktop ==="
check_cmd "hyprland"
check_cmd "waybar"
check_cmd "wofi"
check_cmd "kitty"
if [[ -n "$TARGET_HOME" ]]; then
  check_dir "${TARGET_HOME}/.config/hypr"
  check_dir "${TARGET_HOME}/.config/waybar"
  check_dir "${TARGET_HOME}/.config/kitty"
else
  log "⊙ Skipping user config checks (no TARGET_HOME)"
fi

# ============================================================
#  SECTION 3: GPU Drivers
# ============================================================
log "=== GPU Drivers ==="
if lspci | grep -qi nvidia; then
  check_cmd "nvidia-smi"
  if modinfo nvidia >/dev/null 2>&1; then
    log "✓ NVIDIA driver loaded"
  else
    err "✗ NVIDIA driver not loaded"
    ((ERRORS++))
  fi
elif lspci | grep -qi amd; then
  if modinfo amdgpu >/dev/null 2>&1; then
    log "✓ AMD driver loaded"
  else
    err "✗ AMD driver not loaded"
    ((ERRORS++))
  fi
elif lspci | grep -qi intel; then
  if modinfo i915 >/dev/null 2>&1; then
    log "✓ Intel driver loaded"
  else
    err "✗ Intel driver not loaded"
    ((ERRORS++))
  fi
else
  log "⊙ No discrete GPU detected"
fi

# ============================================================
#  SECTION 4: Audio (PipeWire)
# ============================================================
log "=== Audio (PipeWire) ==="
check_cmd "pactl"
systemctl --user -M "$TARGET_USER" is-active --quiet pipewire 2>/dev/null && \
  log "✓ PipeWire active (user)" || \
  log "⊙ PipeWire may not be active yet"

# ============================================================
#  SECTION 5: Networking
# ============================================================
log "=== Networking ==="
check_service "NetworkManager"
check_cmd "nmcli"

# ============================================================
#  SECTION 6: Virtualization
# ============================================================
log "=== Virtualization ==="
check_cmd "qemu-system-x86_64"
check_cmd "virt-manager"
check_service "libvirtd"

# ============================================================
#  SECTION 7: Containers
# ============================================================
log "=== Containers ==="
check_cmd "docker"
check_service "docker"

# ============================================================
#  SECTION 8: Syncthing / Backups
# ============================================================
log "=== Syncthing & Backups ==="
check_cmd "syncthing"
check_cmd "timeshift"
check_cmd "restic"
check_cmd "rclone"

# ============================================================
#  SECTION 9: Security
# ============================================================
log "=== Security ==="
check_service "firewalld"
check_cmd "apparmor_parser"
check_cmd "firejail"
check_cmd "keepassxc"

# ============================================================
#  SECTION 10: Development
# ============================================================
log "=== Development Tools ==="
check_cmd "git"
check_cmd "gcc"
check_cmd "clang"
check_cmd "python"
check_cmd "node"
check_cmd "cargo"
check_cmd "docker"
check_cmd "neovim"

# ============================================================
#  SECTION 11: CAD / CNC / 3D Printing
# ============================================================
log "=== CAD / CNC / 3D Printing ==="
check_cmd "blender"
check_cmd "freecad"
check_cmd "kicad"
check_cmd "prusa-slicer"
check_cmd "openscad"

# ============================================================
#  SECTION 12: Electrical / FPGA
# ============================================================
log "=== Electrical Engineering / FPGA ==="
check_cmd "ngspice"
check_cmd "qucs-s"
check_cmd "yosys"
check_cmd "nextpnr"
check_cmd "gtkwave"
check_cmd "iverilog"

# ============================================================
#  SECTION 13: Python & Jupyter
# ============================================================
log "=== Python & Jupyter ==="
if command -v python >/dev/null 2>&1; then
  if python -c "import numpy, scipy, pandas, matplotlib" 2>/dev/null; then
    log "✓ Core Python ML stack present"
  else
    err "✗ Core Python ML stack missing"
    ((ERRORS++))
  fi
  
  if python -c "import jupyterlab" 2>/dev/null; then
    log "✓ JupyterLab installed"
  else
    err "✗ JupyterLab missing"
    ((ERRORS++))
  fi
else
  err "✗ Python not found"
  ((ERRORS++))
fi

# ============================================================
#  SECTION 14: CUDA / AI-ML Libraries
# ============================================================
log "=== CUDA / AI-ML Libraries ==="
if command -v nvidia-smi >/dev/null 2>&1; then
  log "✓ NVIDIA CUDA available"
  if python -c "import torch; print(torch.cuda.is_available())" 2>/dev/null; then
    log "✓ PyTorch CUDA support enabled"
  else
    log "⊙ PyTorch found but CUDA not available"
  fi
else
  log "⊙ NVIDIA CUDA not available (non-NVIDIA GPU or no GPU)"
fi

if python -c "import torch" 2>/dev/null; then
  log "✓ PyTorch installed"
else
  err "✗ PyTorch missing"
  ((ERRORS++))
fi

if python -c "import tensorflow" 2>/dev/null; then
  log "✓ TensorFlow installed"
else
  log "⊙ TensorFlow not found (optional)"
fi

# ============================================================
#  SECTION 15: Fonts
# ============================================================
log "=== Fonts ==="
if fc-list | grep -qi "jetbrains" || fc-list | grep -qi "noto"; then
  log "✓ Core fonts present"
else
  err "✗ Expected fonts missing"
  ((ERRORS++))
fi

# ============================================================
#  SECTION 16: User Configs
# ============================================================
log "=== User Configurations ==="
if [[ -n "$TARGET_HOME" ]]; then
  for cfg in hypr hyprlock hypridle waybar kitty fastfetch eww swaync; do
    check_dir "${TARGET_HOME}/.config/${cfg}"
  done
  check_file "${TARGET_HOME}/.anthonyware-installed"
else
  log "⊙ Skipping user config checks (no TARGET_HOME)"
fi

# ============================================================
#  SECTION 17: System Files
# ============================================================
log "=== System Files ==="
check_file "/etc/default/grub"
check_file "/etc/mkinitcpio.conf"

# ============================================================
#  SECTION 18: Homelab Tools
# ============================================================
log "=== Homelab Tools ==="
check_cmd "cockpit"
check_cmd "tailscale"
check_cmd "syncthing"

# ============================================================
#  SUMMARY
# ============================================================
echo "=============================================="
echo " Validation Summary"
echo "=============================================="
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"
echo "=============================================="

if [[ $ERRORS -gt 0 ]]; then
  echo ""
  echo "⚠ FAILED ITEMS:"
  if [[ ${#FAILED_CMDS[@]} -gt 0 ]]; then
    echo ""
    echo "Missing commands (packages):"
    for cmd in "${FAILED_CMDS[@]}"; do
      case "$cmd" in
        qemu-system-x86_64) echo "  • $cmd → sudo pacman -S qemu-full" ;;
        virt-manager) echo "  • $cmd → sudo pacman -S virt-manager" ;;
        waybar) echo "  • $cmd → sudo pacman -S waybar" ;;
        rofi) echo "  • $cmd → sudo pacman -S rofi rofi-calc rofi-emoji" ;;
        hyprland) echo "  • $cmd → sudo pacman -S hyprland" ;;
        kitty) echo "  • $cmd → sudo pacman -S kitty" ;;
        sddm) echo "  • $cmd → sudo pacman -S sddm" ;;
        *) echo "  • $cmd → sudo pacman -S $cmd" ;;
      esac
    done
  fi
  if [[ ${#FAILED_FILES[@]} -gt 0 ]]; then
    echo ""
    echo "Missing files/configs:"
    for file in "${FAILED_FILES[@]}"; do
      echo "  • $file"
    done
    echo ""
    echo "Run: sudo bash install/02-qt6-runtime.sh install/03-hyprland.sh"
  fi
  echo ""
  echo "⚠ Installation validation FAILED. Fix items above and re-run."
  exit 1
else
  echo "✓ Installation validation PASSED."
  exit 0
fi
