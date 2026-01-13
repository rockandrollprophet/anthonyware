#!/usr/bin/env bash
set -euo pipefail

echo "=== ANTHONYWARE IDENTITY STACK INSTALLER ==="

REPO="$HOME/anthonyware"

# ---------------------------------------------------------
# 0. Ensure repo exists
# ---------------------------------------------------------
if [ ! -d "$REPO" ]; then
    echo "Repository not found at $REPO"
    exit 1
fi

# ---------------------------------------------------------
# 1. Install required packages
# ---------------------------------------------------------
echo "[1/10] Installing required packages..."

sudo pacman -S --noconfirm --needed \
    sddm qt6-quickcontrols2 qt6-svg \
    plymouth \
    cava \
    eww-wayland \
    swaync \
    hyprlock hypridle hyprpaper \
    jetbrains-mono-nerd \
    kitty \
    waybar

# ---------------------------------------------------------
# 2. Create config directories
# ---------------------------------------------------------
echo "[2/10] Creating config directories..."

mkdir -p ~/.config/{kitty,fastfetch,sddm,hyprlock,hypridle,plymouth,waybar,cava,eww,swaync}
mkdir -p ~/.config/kitty/colors

# ---------------------------------------------------------
# 3. Deploy system-wide palette
# ---------------------------------------------------------
echo "[3/10] Deploying color palette..."

cp "$REPO/configs/colors/palette.conf" ~/.config/kitty/colors/palette.conf

# ---------------------------------------------------------
# 4. Deploy Kitty theme engine
# ---------------------------------------------------------
echo "[4/10] Installing Kitty theme engine..."

cp "$REPO/configs/kitty/kitty.conf" ~/.config/kitty/
cp "$REPO/configs/kitty/"*.sh ~/.config/kitty/
cp "$REPO/configs/kitty/colors/"*.conf ~/.config/kitty/colors/

chmod +x ~/.config/kitty/*.sh

# Set night mode as default
~/.config/kitty/switch-theme.sh anthonyware-night

# ---------------------------------------------------------
# 5. Deploy Fastfetch identity
# ---------------------------------------------------------
echo "[5/10] Installing Fastfetch identity..."

mkdir -p ~/.config/fastfetch

cp "$REPO/configs/fastfetch/fastfetch.jsonc" ~/.config/fastfetch/config.jsonc
cp "$REPO/configs/fastfetch/ascii-a.txt" ~/.config/fastfetch/ascii-a.txt
cp "$REPO/configs/fastfetch/greeting.sh" ~/.config/fastfetch/greeting.sh
cp "$REPO/configs/fastfetch/health.sh" ~/.config/fastfetch/health.sh

chmod +x ~/.config/fastfetch/*.sh

# ---------------------------------------------------------
# 6. Deploy SDDM theme
# ---------------------------------------------------------
echo "[6/10] Installing SDDM theme..."

sudo mkdir -p /usr/share/sddm/themes/anthonyware
sudo cp -r "$REPO/configs/sddm/theme/anthonyware/"* /usr/share/sddm/themes/anthonyware/

sudo bash -c 'echo -e "[Theme]\nCurrent=anthonyware" > /etc/sddm.conf'
sudo systemctl enable sddm

# ---------------------------------------------------------
# 7. Deploy Hyprlock + Hypridle
# ---------------------------------------------------------
echo "[7/10] Installing Hyprlock + Hypridle..."

mkdir -p ~/.config/hyprlock
mkdir -p ~/.config/hypridle

cp "$REPO/configs/hyprlock/"* ~/.config/hyprlock/
cp "$REPO/configs/hypridle/hypridle.conf" ~/.config/hypridle/

# ---------------------------------------------------------
# 8. Deploy Plymouth theme
# ---------------------------------------------------------
echo "[8/10] Installing Plymouth theme..."

sudo mkdir -p /usr/share/plymouth/themes/anthonyware
sudo cp "$REPO/configs/plymouth/anthonyware/"* /usr/share/plymouth/themes/anthonyware/

sudo sed -i 's/^HOOKS=.*/HOOKS=(base udev plymouth autodetect modconf block filesystems keyboard fsck)/' /etc/mkinitcpio.conf
sudo mkinitcpio -P

sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="quiet splash plymouth.enable=1 /' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# ---------------------------------------------------------
# 9. Deploy Waybar + Cava + Eww visualizer
# ---------------------------------------------------------
echo "[9/10] Installing Waybar + Cava + Eww visualizer..."

cp "$REPO/configs/waybar/config.jsonc" ~/.config/waybar/
cp "$REPO/configs/waybar/style.css" ~/.config/waybar/

cp "$REPO/configs/cava/config" ~/.config/cava/config

mkdir -p ~/.config/eww
cp "$REPO/configs/eww/"* ~/.config/eww/

# ---------------------------------------------------------
# 10. Deploy SwayNC theme loader
# ---------------------------------------------------------
echo "[10/10] Installing SwayNC theme loader..."

cp "$REPO/configs/swaync/theme-loader.sh" ~/.config/swaync/theme-loader.sh
chmod +x ~/.config/swaync/theme-loader.sh

~/.config/swaync/theme-loader.sh

echo "=== ANTHONYWARE IDENTITY STACK INSTALLED SUCCESSFULLY ==="
echo "Reboot to activate Plymouth + SDDM + full identity chain."
