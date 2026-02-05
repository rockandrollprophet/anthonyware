#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [22] Homelab & Server Tools ==="

${SUDO} pacman -S --noconfirm --needed \
    cockpit \
  cockpit-machines \
  cockpit-storaged \
  cockpit-packagekit \
  cockpit-podman \
    tailscale \
    syncthing \
    rclone \
    rsync \
    samba \
  nfs-utils \
  podman \
  podman-compose \
  btrfs-progs \
  snapper \
  timeshift \
  avahi \
  nss-mdns \
  iperf3 \
  mtr \
  ethtool \
  fail2ban \
  netdata \
  prometheus \
  grafana \
  restic \
  borgbackup \
  minio-client \
  wakeonlan \
  libvirt \
  qemu-base \
  dnsmasq \
  virt-install \
  edk2-ovmf \
  cifs-utils \
  dosfstools \
  mtools \
  tlp \
  powertop

optional_pacman_packages=(
  bridge-utils
)

if pacman -Qi docker >/dev/null 2>&1; then
  echo "NOTICE: 'docker' is installed; skipping podman-docker to avoid conflicts"
else
  optional_pacman_packages+=(podman-docker)
fi

for pkg in "${optional_pacman_packages[@]}"; do
  if ${SUDO} pacman -Si "$pkg" >/dev/null 2>&1; then
    ${SUDO} pacman -S --noconfirm --needed "$pkg"
  else
    echo "NOTICE: '$pkg' not found in repos; skipping"
  fi
done

if command -v yay >/dev/null; then
  yay -S --noconfirm --needed \
    auto-cpufreq || echo "WARNING: one or more AUR packages failed to install via yay"
else
  echo "NOTICE: 'yay' not found; install auto-cpufreq manually if desired"
fi

${SUDO} systemctl enable --now cockpit.socket
${SUDO} systemctl enable --now tailscaled
${SUDO} systemctl enable --now syncthing@"$USER"
${SUDO} systemctl enable --now avahi-daemon
${SUDO} systemctl enable --now fail2ban
${SUDO} systemctl enable --now podman.socket
${SUDO} systemctl enable --now libvirtd

echo "=== Homelab Tools Setup Complete ==="