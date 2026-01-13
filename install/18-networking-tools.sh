#!/usr/bin/env bash
set -euo pipefail

echo "=== [18] Networking Tools ==="

sudo pacman -S --noconfirm --needed \
    iperf3 \
    nmap \
    tcpdump \
    wireshark-qt \
    traceroute \
    bind \
    net-tools \
    openssh \
    rsync

sudo usermod -aG wireshark "$USER"

echo "=== Networking Tools Setup Complete ==="