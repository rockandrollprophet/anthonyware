#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [18] Networking Tools ==="


${SUDO} pacman -S --noconfirm --needed \
  iperf3 \
  nmap \
  tcpdump \
  wireshark-qt \
  traceroute \
  mtr \
  ethtool \
  socat \
  whois \
  arp-scan \
  nftables \
  curl \
  httpie \
  iproute2 \
  openssh \
  rsync \
  bind-tools \
  openbsd-netcat

${SUDO} usermod -aG wireshark "$USER"

echo "=== Networking Tools Setup Complete ==="