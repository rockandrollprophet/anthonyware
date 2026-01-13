#!/usr/bin/env bash
set -euo pipefail

echo "=== Syncing dotfiles and configs ==="

rsync -avh ~/.config/hypr ~/anthonyware/configs/hypr/
rsync -avh ~/.config/waybar ~/anthonyware/configs/waybar/
rsync -avh ~/.config/kitty ~/anthonyware/configs/kitty/

echo "=== Sync Complete ==="
