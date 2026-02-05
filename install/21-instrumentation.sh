#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [21] Instrumentation & Lab Tools ==="

${SUDO} pacman -S --noconfirm --needed \
    python-usbtmc \
    python-pyusb \
    python-pyftdi \
    python-pyvisa \
    libsigrok \
    libsigrokdecode \
    sigrok-cli \
    pulseview \
    labplot \
    gnuplot

if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
  scpi-tools \
  lxi-tools \
  python-pyvisa-py || echo "WARNING: one or more AUR packages failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install scpi-tools manually if desired"
fi

if command -v python >/dev/null; then
  python -m pip install --user --break-system-packages --upgrade \
    pymeasure \
    qcodes || echo "WARNING: pip install for pymeasure/qcodes failed"

  python -m pip install --user --break-system-packages --upgrade \
    scpi || echo "WARNING: pip install for scpi failed"

  python -m pip install --user --break-system-packages --upgrade \
    pyvisa-gui || echo "WARNING: pyvisa-gui not found on PyPI"
else
  echo "NOTICE: python not found; skipping pip installs (pymeasure, qcodes, pyvisa-gui)"
fi

echo "=== Instrumentation Setup Complete ==="