#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [12] Printing Stack ==="

${SUDO} pacman -S --noconfirm --needed \
    cups \
    cups-pdf \
    system-config-printer \
    ghostscript \
    gsfonts \
    foomatic-db-engine \
    foomatic-db \
    foomatic-db-ppds \
    gutenprint \
    avahi \
    nss-mdns

# Enable services
${SUDO} systemctl enable --now cups.service
${SUDO} systemctl enable --now avahi-daemon.service

# Ensure mDNS is configured
${SUDO} sed -i 's/^hosts:.*/hosts: files mdns_minimal [NOTFOUND=return] dns myhostname/' /etc/nsswitch.conf

# MobilityPrint (if you later add the client)
echo "# Anthonyware: MobilityPrint client can be installed later via AUR when needed."

echo "=== Printing Stack Setup Complete ==="