#!/usr/bin/env bash
set -euo pipefail

echo "=== [19] Electrical Engineering Tools ==="

# Core EE/electronics
sudo pacman -S --noconfirm --needed \
    kicad \
    ngspice \
    qucs-s \
    geda \
    gerbv

# Signal analysis and visualization
sudo pacman -S --noconfirm --needed \
    sigrok-cli \
    pulseview

# Microcontroller programming
sudo pacman -S --noconfirm --needed \
    arduino-cli \
    openocd \
    avrdude \
    dfu-util \
    arm-none-eabi-gcc \
    arm-none-eabi-gdb

# Test and measurement
sudo pacman -S --noconfirm --needed \
    python-usbtmc \
    python-pyvisa

# Scientific / numerical computation for circuit analysis
sudo pacman -S --noconfirm --needed \
    octave \
    octave-control \
    octave-signal

# Visualization and plotting
sudo pacman -S --noconfirm --needed \
    gnuplot

# Advanced tools (AUR)
if command -v yay >/dev/null; then
    echo "[19] Installing advanced EE tools from AUR..."
    
    # LTSpice (SPICE simulator wrapper/UI)
    yay -S --noconfirm --needed ltspice || echo "WARNING: ltspice failed to install"
    
    # SCPI tools for instrument control
    yay -S --noconfirm --needed scpi-tools || echo "WARNING: scpi-tools failed to install"
    
    # PCB layout assistant
    yay -S --noconfirm --needed pcb || echo "WARNING: pcb failed to install (optional)"
    
    # High-speed protocol analyzers / logic analyzers
    yay -S --noconfirm --needed sigrok || echo "WARNING: sigrok failed to install"
    
else
    echo "NOTICE: 'yay' not found; install AUR EE tools manually if desired"
fi

echo "=== Electrical Engineering Setup Complete ==="
echo "Recommended: Install LTSpice, Proteus, or PSPICE via Windows VM for advanced simulation"