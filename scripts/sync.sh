#!/usr/bin/env bash
set -euo pipefail

echo "=== Syncing dotfiles and configs ==="

rsync -avh ~/.config/hypr ~/anthonyware-arch/configs/hypr/
rsync -avh ~/.config/waybar ~/anthonyware-arch/configs/waybar/
rsync -avh ~/.config/kitty ~/anthonyware-arch/configs/kitty/

echo "=== Sync Complete ==="
