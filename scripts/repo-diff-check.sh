#!/usr/bin/env bash
set -euo pipefail

echo "=== Anthonyware Repo Diff Checker ==="

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPO_ROOT"

# Expected files (relative paths)
cat << 'EOF' | sort > /tmp/anthonyware-expected.txt
README.md
install/0-README.md
install/run-all.sh
install/00-preflight-checks.sh
install/01-base-system.sh
install/02-gpu-drivers.sh
install/03-hyprland.sh
install/04-daily-driver.sh
install/05-dev-tools.sh
install/06-ai-ml.sh
install/07-cad-cnc-3dprinting.sh
install/08-hardware-support.sh
install/09-security.sh
install/10-backups.sh
install/11-vfio-windows-vm.sh
install/12-printing.sh
install/13-fonts.sh
install/14-portals.sh
install/15-power-management.sh
install/16-firmware.sh
install/17-steam.sh
install/18-networking-tools.sh
install/19-electrical-engineering.sh
install/20-fpga-toolchain.sh
install/21-instrumentation.sh
install/22-homelab-tools.sh
install/23-terminal-qol.sh
install/24-cleanup-and-verify.sh
install/25-color-management.sh
install/26-archive-tools.sh
install/27-zram-swap.sh
install/28-audio-routing.sh
install/29-misc-utilities.sh
install/30-finalize.sh
install/31-wayland-recording.sh
install/32-xwayland-legacy.sh
install/33-cleaner.sh
install/99-update-everything.sh
configs/0-README.md
configs/hypr/0-README.md
configs/hypr/hyprland.conf
configs/hypr/hyprpaper.conf
configs/hypr/hyprlock.conf
configs/waybar/0-README.md
configs/waybar/config.jsonc
configs/waybar/style.css
configs/kitty/0-README.md
configs/kitty/kitty.conf
configs/mako/0-README.md
configs/mako/config
configs/eww/0-README.md
configs/eww/eww.yuck
configs/eww/style.scss
configs/wofi/0-README.md
configs/wofi/style.css
configs/systemd/0-README.md
configs/systemd/cliphist.service
docs/0-README.md
docs/install-guide.md
docs/security-hardening.md
docs/workflow-daily-driver.md
docs/workflow-ai-ml.md
docs/workflow-cad.md
docs/workflow-cnc.md
docs/workflow-3dprinting.md
docs/workflow-backups.md
docs/update-strategy.md
docs/workflow-vfio.md
docs/first-boot-checklist.md
docs/branding-guide.md
vm/0-README.md
vm/vfio-setup.md
vm/windows-install.md
vm/gpu-passthrough-checklist.md
vm/iommu-checklist.md
vm/touchdesigner-setup.md
scripts/0-README.md
scripts/update-everything.sh
scripts/backup-home.sh
scripts/backup-system.sh
scripts/sync.sh
scripts/maintenance.sh
scripts/repo-diff-check.sh
scripts/post-install-validate.sh
.gitignore
configs/colors/0-README.md
configs/colors/palette.conf
configs/kitty/switch-theme.sh
configs/kitty/random-theme.sh
configs/kitty/toggle-night.sh
configs/kitty/colors/palette.conf
configs/kitty/colors/anthonyware.conf
configs/kitty/colors/anthonyware-night.conf
configs/kitty/colors/anthonyware-highcontrast.conf
configs/kitty/colors/anthonyware-dimmed.conf
configs/kitty/colors/anthonyware-matrix.conf
configs/kitty/colors/solarized-dark.conf
configs/kitty/colors/dracula.conf
configs/fastfetch/0-README.md
configs/fastfetch/fastfetch.jsonc
configs/fastfetch/ascii-a.txt
configs/fastfetch/greeting.sh
configs/fastfetch/health.sh
configs/sddm/theme/anthonyware/0-README.md
configs/sddm/theme/anthonyware/theme.conf
configs/sddm/theme/anthonyware/metadata.desktop
configs/sddm/theme/anthonyware/Main.qml
configs/sddm/theme/anthonyware/shutdown.qml
configs/sddm/theme/anthonyware/Background.png
configs/sddm/theme/anthonyware/A.png
configs/hyprlock/0-README.md
configs/hyprlock/background.png
configs/hyprlock/A.png
configs/hypridle/0-README.md
configs/hypridle/hypridle.conf
configs/plymouth/anthonyware/0-README.md
configs/plymouth/anthonyware/anthonyware.plymouth
configs/plymouth/anthonyware/script.js
configs/plymouth/anthonyware/background.png
configs/plymouth/anthonyware/A.png
configs/waybar/modules/visualizer
configs/cava/0-README.md
configs/cava/config
configs/eww/visualizer.yuck
configs/eww/visualizer.scss
configs/swaync/0-README.md
configs/swaync/style.css
configs/swaync/theme-loader.sh
scripts/enable-sddm.sh
scripts/enable-plymouth.sh
scripts/enable-visualizer.sh
scripts/install-all.sh
configs/apparmor/0-README.md
configs/firejail/0-README.md
configs/firewalld/0-README.md
configs/pipewire/0-README.md
configs/syncthing/0-README.md
configs/vfio/0-README.md
configs/wireplumber/0-README.md
scripts/gpu-check.sh
vm/virt-manager-settings.md
EOF
find . -maxdepth 5 -type f \
  | sed 's|^\./||' \
  | sort > /tmp/anthonyware-actual.txt

echo
echo "--- Missing files (expected but not found) ---"
comm -23 /tmp/anthonyware-expected.txt /tmp/anthonyware-actual.txt || true

echo
echo "--- Extra files (present but not in expected list) ---"
comm -13 /tmp/anthonyware-expected.txt /tmp/anthonyware-actual.txt || true

echo
echo "=== Repo diff check complete ==="