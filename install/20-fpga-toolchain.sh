#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [20] FPGA Toolchain / Hardware Description Languages ==="

# Core FPGA Flow (Pacman)
echo "[20] Installing core FPGA synthesis, place & route, and simulation tools..."
${SUDO} pacman -S --noconfirm --needed \
  yosys-nightly \
  nextpnr-all-nightly \
    iverilog \
    verilator \
    gtkwave \
    python-pyserial \
  python-pyusb \
    klayout

# Device-specific bitstream tools + verification (AUR)
if command -v yay >/dev/null; then
    echo "[20] Installing device-specific FPGA tools and verification frameworks..."
    
    # Lattice iCE40 support
    yay -S --noconfirm --needed icestorm-nightly || echo "WARNING: icestorm-nightly (iCE40) failed"
    
    # Gowin FPGA support
    yay -S --noconfirm --needed prjoxide-nightly || echo "WARNING: prjoxide-nightly (Gowin) failed"
    
    # Universal FPGA programmer (already in Group 19, ensuring present)
    yay -S --noconfirm --needed openfpgaloader || echo "WARNING: openfpgaloader failed"
    
    # Formal verification
    yay -S --noconfirm --needed symbiyosys-git || echo "WARNING: symbiyosys-git (formal verification) failed"
    
    # Python testbench framework
    yay -S --noconfirm --needed python-cocotb || echo "WARNING: python-cocotb failed"
    
    # Project management
    yay -S --noconfirm --needed python-edalize || echo "WARNING: python-edalize (backend abstraction) failed"
    
    # ASIC / Advanced design
    yay -S --noconfirm --needed openroad-git || echo "WARNING: openroad-git (chip design) failed"
    yay -S --noconfirm --needed magic || echo "WARNING: magic (VLSI layout) failed"

    # VHDL simulator (mcode backend) + dependency fix for Python 3.14
    yay -S --noconfirm --needed python-pytooling || echo "WARNING: python-pytooling failed"
    yay -S --noconfirm --needed ghdl-mcode-git || echo "WARNING: ghdl-mcode-git (VHDL) failed"
    
else
    echo "NOTICE: 'yay' not found; install AUR FPGA tools manually if desired"
fi

# Python extras for enhanced testing and connectivity
echo "[20] Installing Python FPGA development extras..."
pip install --user --break-system-packages cocotb-test pytest pyftdi 2>/dev/null || echo "WARNING: Some pip packages failed"

# Documentation
echo ""
echo "=== [20] FPGA Toolchain Setup Complete ==="
echo "Core Flow:"
echo "  - Yosys: Verilog synthesis"
echo "  - nextpnr-all: Place and route"
echo "  - iverilog/verilator/gtkwave: Simulation and waveform viewing"
echo "  - GHDL (mcode): VHDL simulation"
echo ""
echo "Device Support:"
echo "  - icestorm: Lattice iCE40"
echo "  - prjoxide: Gowin FPGAs"
echo "  - openfpgaloader: Universal programmer"
echo ""
echo "Verification:"
echo "  - SymbiYosys: Formal verification"
echo "  - cocotb: Python-based testbenches"
echo ""
echo "ASIC/Advanced:"
echo "  - openroad-git: Digital ASIC flow"
echo "  - klayout/magic: Layout tools"
echo ""
echo "For Xilinx/Altera: Use proprietary tools (Vivado/Quartus)"