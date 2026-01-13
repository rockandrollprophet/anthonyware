#!/usr/bin/env bash
set -euo pipefail

echo "=== [12] Printing Stack ==="

sudo pacman -S --noconfirm --needed \
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
sudo systemctl enable --now cups.service
sudo systemctl enable --now avahi-daemon.service

# Ensure mDNS is configured
sudo sed -i 's/^hosts:.*/hosts: files mdns_minimal [NOTFOUND=return] dns myhostname/' /etc/nsswitch.conf

# MobilityPrint (if you later add the client)
echo "# Anthonyware: MobilityPrint client can be installed later via AUR when needed."

echo "=== Printing Stack Setup Complete ==="