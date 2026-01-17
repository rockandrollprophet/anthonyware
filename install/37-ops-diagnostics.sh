#!/usr/bin/env bash
set -euo pipefail

# Anthonyware - Operations & Diagnostics tooling
# Installs lightweight diagnostics and troubleshooting utilities.

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  echo "[DRY_RUN] Would install diagnostics packages"
  exit 0
fi

pacman -Sy --noconfirm --needed \
  smartmontools \
  nvme-cli \
  ethtool \
  iperf3 \
  mtr \
  bind \
  lsof \
  strace \
  tcpdump \
  socat \
  usbutils \
  lm_sensors \
  sysstat \
  btop

# Optional: create a placeholder smartd config (do not enable service by default)
if [[ ! -f /etc/smartd.conf ]]; then
  cat <<'EOF' > /etc/smartd.conf
# smartd placeholder configuration for Anthonyware
# Uncomment and adjust for your drives, e.g.:
# DEVICESCAN -H -l error -l selftest -l selective -s (S/../.././02) -m root
EOF
fi

echo "[ops-diagnostics] Installed diagnostics utilities."
