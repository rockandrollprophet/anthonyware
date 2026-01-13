#!/usr/bin/env bash
set -euo pipefail

echo "=== [20] FPGA Toolchain ==="

sudo pacman -S --noconfirm --needed \
    yosys \
    nextpnr \
    iverilog \
    gtkwave

echo "=== FPGA Toolchain Setup Complete ==="