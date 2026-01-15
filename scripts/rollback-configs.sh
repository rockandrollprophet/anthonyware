#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  rollback-configs.sh
#  Restore .anthonyware.bak backup files
# ============================================================

echo "=== Anthonyware Config Rollback ==="
echo "This script restores backed-up system config files."
echo

BACKUPS=(
  "/etc/sddm.conf"
  "/etc/sddm.conf.d/10-qt6-env.conf"
  "/etc/default/grub"
  "/etc/mkinitcpio.conf"
  "/etc/modules-load.d/vfio.conf"
  "/etc/modprobe.d/blacklist-nvidia.conf"
)

RESTORED=0
MISSING=0

for orig in "${BACKUPS[@]}"; do
  bak="${orig}.anthonyware.bak"
  if [[ -f "$bak" ]]; then
    echo "Restoring: $orig"
    sudo cp -v "$bak" "$orig"
    ((RESTORED++))
  else
    echo "No backup: $orig"
    ((MISSING++))
  fi
done

echo
echo "=== Rollback Summary ==="
echo "Restored: $RESTORED files"
echo "Missing:  $MISSING backups"
echo

if [[ $RESTORED -gt 0 ]]; then
  echo "⚠ Rebuild required for:"
  echo "  sudo mkinitcpio -P"
  echo "  sudo grub-mkconfig -o /boot/grub/grub.cfg"
  echo "  sudo systemctl reboot"
fi
