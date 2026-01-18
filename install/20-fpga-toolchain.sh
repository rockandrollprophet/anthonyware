#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [20] FPGA Toolchain / Hardware Description Languages ==="

# Open-source FPGA tools (Lattice, ECP5, iCE40)
${SUDO} pacman -S --noconfirm --needed \
    yosys \
    nextpnr \
    iverilog \
    gtkwave \
    verilator

# Simulation and verification
${SUDO} pacman -S --noconfirm --needed \
    ghdl || echo "WARNING: ghdl install failed (VHDL simulator)"

# Hardware description languages and tooling
${SUDO} pacman -S --noconfirm --needed \
    python-pyserial \
    python-usb

# Advanced FPGA flows (AUR)
if command -v yay >/dev/null; then
    echo "[20] Installing advanced FPGA tools..."
    
    # IceStorm (iCE40 FPGA programming)
    yay -S --noconfirm --needed icestorm || echo "WARNING: icestorm failed to install"
    
    # Project Trellis (ECP5 FPGA)
    yay -S --noconfirm --needed prjoxide || echo "WARNING: prjoxide failed to install"
    
    # Symbio (symbol/schematic generator)
    yay -S --noconfirm --needed openroad || echo "WARNING: openroad (chip design) failed to install"
    
else
    echo "NOTICE: 'yay' not found; install advanced FPGA tools manually if desired"
fi

# Documentation
echo "[20] FPGA Toolchain includes:"
echo "  - Yosys: Verilog synthesis"
echo "  - nextpnr: Place and route"
echo "  - iverilog/gtkwave: Simulation and waveform viewing"
echo "  - verilator: Fast Verilog simulator"
echo "  - GHDL: VHDL simulation"

echo "=== FPGA Toolchain Setup Complete ==="
echo "For Xilinx/Altera tools: Use Windows VM or purchase licenses"
echo "For open designs: Use Yosys + nextpnr (open-source FPGA flow)"