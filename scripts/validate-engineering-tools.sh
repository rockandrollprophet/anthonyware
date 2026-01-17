#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Anthonyware Engineering Tools Validation
# Verifies that all CAD, EE, FPGA, ML, and scientific computing tools are installed
###############################################################################

BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

echo -e "${BOLD}=== Anthonyware Engineering Tools Validation ===${RESET}"
echo ""

# Helper functions
check_command() {
    local cmd="$1"
    local label="${2:-$cmd}"
    
    if command -v "$cmd" &>/dev/null; then
        echo -e "${GREEN}✓${RESET} $label"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} $label (NOT FOUND)"
        ((FAILED++))
        return 1
    fi
}

check_pacman() {
    local pkg="$1"
    local label="${2:-$pkg}"
    
    if pacman -Q "$pkg" &>/dev/null; then
        echo -e "${GREEN}✓${RESET} $label"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} $label (NOT INSTALLED)"
        ((FAILED++))
        return 1
    fi
}

check_python_module() {
    local module="$1"
    local label="${2:-$module}"
    
    if python -c "import $module" 2>/dev/null; then
        echo -e "${GREEN}✓${RESET} $label"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}!${RESET} $label (PIP INSTALL RECOMMENDED)"
        ((WARNINGS++))
        return 1
    fi
}

###############################################################################
# 1. CAD / CNC / 3D Printing
###############################################################################
echo -e "${BOLD}[1] CAD / CNC / 3D Printing Stack${RESET}"
check_pacman "blender" "Blender 3D"
check_pacman "kicad" "KiCAD"
check_pacman "freecad" "FreeCAD"
check_pacman "openscad" "OpenSCAD"
check_command "fusion360" "Fusion 360" || echo -e "${YELLOW}!${RESET} Fusion 360 (AUR or web-based)"
check_pacman "meshlab" "MeshLab (mesh processing)"

# CNC tools
check_command "candle" "Candle (CNC)" || echo -e "${YELLOW}!${RESET} Candle (AUR)"
check_command "bcnc" "bCNC" || echo -e "${YELLOW}!${RESET} bCNC (AUR)"

# 3D printing
check_pacman "prusa-slicer" "Prusa Slicer" || echo -e "${YELLOW}!${RESET} Prusa Slicer"
check_command "cura" "Cura" || echo -e "${YELLOW}!${RESET} Cura (AUR)"
check_pacman "octoprint" "OctoPrint" || echo -e "${YELLOW}!${RESET} OctoPrint"

echo ""

###############################################################################
# 2. Electrical Engineering / Electronics
###############################################################################
echo -e "${BOLD}[2] Electrical Engineering / Electronics${RESET}"
check_pacman "kicad" "KiCAD PCB Design"
check_pacman "ngspice" "ngspice (SPICE simulator)"
check_pacman "qucs-s" "QUCS-S (circuit simulator)"
check_pacman "geda" "gEDA (schematic capture)" || echo -e "${YELLOW}!${RESET} gEDA"
check_pacman "gerbv" "GerbView (Gerber viewer)"
check_pacman "sigrok-cli" "sigrok (logic analyzer)"
check_pacman "pulseview" "PulseView (analyzer GUI)"
check_pacman "octave" "GNU Octave (numerical computing)"
check_pacman "gnuplot" "Gnuplot (plotting)"

# Microcontroller tools
check_pacman "arduino-cli" "Arduino CLI"
check_pacman "openocd" "OpenOCD (JTAG debugger)"
check_pacman "avrdude" "avrdude (AVR programming)"
check_pacman "arm-none-eabi-gcc" "ARM embedded GCC toolchain"

echo ""

###############################################################################
# 3. FPGA / Hardware Design
###############################################################################
echo -e "${BOLD}[3] FPGA / Hardware Description Languages${RESET}"
check_pacman "yosys" "Yosys (Verilog synthesis)"
check_pacman "nextpnr" "nextpnr (place and route)"
check_pacman "iverilog" "Icarus Verilog"
check_pacman "gtkwave" "GTKWave (waveform viewer)"
check_pacman "verilator" "Verilator (fast simulator)"
check_pacman "ghdl" "GHDL (VHDL simulator)" || echo -e "${YELLOW}!${RESET} GHDL"

echo ""

###############################################################################
# 4. AI / Machine Learning / Scientific Computing
###############################################################################
echo -e "${BOLD}[4] AI / Machine Learning / Scientific Computing${RESET}"
check_python_module "numpy" "NumPy"
check_python_module "scipy" "SciPy"
check_python_module "pandas" "Pandas"
check_python_module "scikit_learn" "Scikit-learn"
check_python_module "matplotlib" "Matplotlib"
check_python_module "torch" "PyTorch"
check_python_module "tensorflow" "TensorFlow"
check_python_module "sympy" "SymPy (symbolic math)"
check_python_module "networkx" "NetworkX (graphs)"

# Jupyter
check_command "jupyter" "Jupyter" || check_command "jupyter-lab" "JupyterLab"
check_python_module "jupyterlab" "JupyterLab"
check_python_module "notebook" "Jupyter Notebook"

# Visualization
check_python_module "plotly" "Plotly" || echo -e "${YELLOW}!${RESET} Plotly"
check_python_module "bokeh" "Bokeh" || echo -e "${YELLOW}!${RESET} Bokeh"

# FEA/Meshing
check_command "gmsh" "Gmsh (meshing)" || echo -e "${YELLOW}!${RESET} Gmsh (AUR)"

echo ""

###############################################################################
# 5. Graphics / Image Processing / Rendering
###############################################################################
echo -e "${BOLD}[5] Graphics / Image Processing / Rendering${RESET}"
check_pacman "gimp" "GIMP (image editor)"
check_command "convert" "ImageMagick (CLI image tools)"
check_pacman "rawtherapee" "RawTherapee (RAW processing)"
check_pacman "krita" "Krita (digital painting)"
check_pacman "ffmpeg" "FFmpeg (video encoding)"
check_command "blender" "Blender (3D rendering)" || check_pacman "blender" "Blender"

echo ""

###############################################################################
# 6. Development Tools (from base system)
###############################################################################
echo -e "${BOLD}[6] Development Tools${RESET}"
check_command "git" "Git"
check_command "gcc" "GCC"
check_command "python" "Python 3"
check_command "npm" "Node.js/npm" || echo -e "${YELLOW}!${RESET} npm"
check_command "docker" "Docker" || echo -e "${YELLOW}!${RESET} Docker"
check_command "cmake" "CMake"
check_command "make" "Make"

echo ""

###############################################################################
# 7. Virtualization (for VFIO / Windows VM)
###############################################################################
echo -e "${BOLD}[7] Virtualization / VFIO (for Windows CAD software)${RESET}"
check_pacman "qemu-full" "QEMU"
check_pacman "virt-manager" "Virt-Manager"
check_pacman "libvirt" "libvirt"
check_pacman "edk2-ovmf" "UEFI firmware (OVMF)"
check_pacman "virtio-win" "VirtIO drivers" || echo -e "${YELLOW}!${RESET} VirtIO drivers for Windows"

echo -e "${YELLOW}NOTE:${RESET} For SolidWorks, Siemens NX: Install inside VFIO Windows VM"
echo ""

###############################################################################
# 8. Monitoring / Diagnostics
###############################################################################
echo -e "${BOLD}[8] System Monitoring / Diagnostics${RESET}"
check_command "htop" "htop (system monitor)"
check_command "btop" "btop (system monitor)"
check_command "nvidia-smi" "nvidia-smi (GPU monitor)" || echo -e "${YELLOW}!${RESET} nvidia-smi (requires GPU drivers)"
check_command "lsblk" "lsblk (disk info)"
check_command "inxi" "inxi (system info)" || echo -e "${YELLOW}!${RESET} inxi"

echo ""

###############################################################################
# Summary
###############################################################################
echo -e "${BOLD}=== Summary ===${RESET}"
echo -e "Passed: ${GREEN}$PASSED${RESET}"
echo -e "Warnings: ${YELLOW}$WARNINGS${RESET}"
echo -e "Failed: ${RED}$FAILED${RESET}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical engineering tools are installed!${RESET}"
    exit 0
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}! Some optional tools are missing. Consider installing via 'yay' or pip.${RESET}"
    exit 0
else
    echo -e "${RED}✗ Some critical tools are missing. Run install scripts again.${RESET}"
    exit 1
fi
