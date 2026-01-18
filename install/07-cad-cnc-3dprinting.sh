#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [07] CAD / CNC / 3D Printing Stack ==="
echo "NOTE: SolidWorks, Siemens NX, and other Windows-only CAD tools run in VFIO Windows VM with GPU passthrough."
echo "      See docs/workflow-cad.md and docs/workflow-vfio.md for VM setup and licensing guidance."

# Core CAD tools (open-source, native)
${SUDO} pacman -S --noconfirm --needed \
    blender \
    kicad \
    freecad \
    openscad

# Fusion 360 (AUR, cloud-based, native auth)
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed fusion360-bin || echo "WARNING: fusion360-bin failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install fusion360-bin manually if desired"
fi

# Web-based CAD (runs in browser)
# Onshape, SketchUp Free, TinkerCAD, etc. available via Zen Browser

# Professional CAD tools (AUR or requires manual install)
if command -v yay >/dev/null; then
    echo "[07] Attempting to install professional CAD tools via AUR..."
    # LibreCAD (2D CAD, open-source)
    yay -S --noconfirm --needed librecad || echo "WARNING: librecad failed to install"
    
    # Upverter (online, browser-based)
    # No native package; use via browser
else
    echo "NOTICE: 'yay' not found; CAD tools available via browser or manual install"
fi

# Advanced geometry / computational design
${SUDO} pacman -S --noconfirm --needed \
    python-shapely || echo "WARNING: python-shapely install failed (optional, for scripted CAD)"

# CNC / Laser / Machining tools
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        candle \
        universal-gcode-sender-bin \
        bcnc \
        openbuilds-control-bin || echo "WARNING: Some CNC AUR packages failed to install"
else
    echo "NOTICE: 'yay' not found; install CNC AUR packages manually"
fi

# Laser engraving
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed lasergrbl-bin || echo "WARNING: lasergrbl-bin failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install lasergrbl-bin manually if desired"
fi

# 3D printing slicers
${SUDO} pacman -S --noconfirm --needed \
    prusa-slicer || echo "WARNING: prusa-slicer install failed"

if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        cura-bin \
        lychee-slicer-bin || echo "WARNING: Some slicer AUR packages failed to install"
else
    echo "NOTICE: 'yay' not found; install cura-bin/lychee-slicer-bin manually if desired"
fi

# 3D printer ecosystem (OctoPrint, Mainsail, Fluidd, Klipper support)
${SUDO} pacman -S --noconfirm --needed \
    octoprint || echo "WARNING: octoprint install failed"

if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        mainsail \
        fluidd || echo "WARNING: mainsail/fluidd failed to install"
else
    echo "NOTICE: 'yay' not found; install mainsail/fluidd manually if desired"
fi

# Mesh processing and repair
${SUDO} pacman -S --noconfirm --needed \
    meshlab || echo "WARNING: meshlab install failed"

# Point cloud processing
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed cloudcompare || echo "WARNING: cloudcompare failed to install"
else
    echo "NOTICE: 'yay' not found; install cloudcompare manually if needed"
fi

echo "=== CAD / CNC / 3D Printing Setup Complete ==="
echo "Windows-only CAD (SolidWorks, Siemens NX): Install inside VFIO Windows VM"
echo "Web-based CAD (Onshape, TinkerCAD): Use Zen Browser"
echo "For GPU passthrough config: See vm/*.md"