#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  health-dashboard.sh
#  Quick system health summary for Anthonyware OS
# ============================================================

echo "=== Anthonyware Health Dashboard ==="
echo

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf "[ ✓ ] %s\n" "$label"
  else
    printf "[ ✗ ] %s\n" "$label"
  fi
}

# ============================================================
#  Core Services
# ============================================================
echo "— Core Services —"
check "NetworkManager" systemctl is-active --quiet NetworkManager
check "PipeWire (user)" systemctl --user is-active --quiet pipewire
check "Docker" systemctl is-active --quiet docker
check "libvirtd" systemctl is-active --quiet libvirtd

# ============================================================
#  User Services
# ============================================================
echo
echo "— User Services —"
check "Syncthing" systemctl --user is-active --quiet syncthing@"${USER}"
check "Tailscale" systemctl is-active --quiet tailscaled

# ============================================================
#  Desktop & Display
# ============================================================
echo
echo "— Desktop Environment —"
check "Hyprland" command -v hyprland
check "Waybar" command -v waybar
check "Kitty" command -v kitty
check "SDDM" command -v sddm

# ============================================================
#  System Tools
# ============================================================
echo
echo "— System Tools —"
check "Timeshift" command -v timeshift
check "Backups" command -v restic
check "Git" command -v git

# ============================================================
#  Development
# ============================================================
echo
echo "— Development Tools —"
check "Python" command -v python
check "Node.js" command -v node
check "Rust" command -v cargo
check "Docker" command -v docker

# ============================================================
#  AI/ML
# ============================================================
echo
echo "— AI/ML Stack —"
if command -v python >/dev/null 2>&1; then
  check "NumPy" python -c "import numpy"
  check "Pandas" python -c "import pandas"
  check "PyTorch" python -c "import torch"
  check "TensorFlow" python -c "import tensorflow" || true
  check "JupyterLab" python -c "import jupyterlab"
fi

# ============================================================
#  CAD / EE Tools
# ============================================================
echo
echo "— CAD / CAM / EE Tools —"
check "Blender" command -v blender
check "FreeCAD" command -v freecad
check "KiCAD" command -v kicad
check "Prusa Slicer" command -v prusa-slicer
check "Yosys (FPGA)" command -v yosys

# ============================================================
#  GPU
# ============================================================
echo
echo "— GPU & Graphics —"
if command -v nvidia-smi >/dev/null 2>&1; then
  check "NVIDIA CUDA" nvidia-smi
else
  if lspci | grep -qi nvidia; then
    check "NVIDIA (disabled)" false || true
  else
    echo "[ • ] No NVIDIA GPU detected"
  fi
fi

# ============================================================
#  Summary
# ============================================================
echo
echo "=== End of Report ==="
