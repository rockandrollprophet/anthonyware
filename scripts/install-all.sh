#!/usr/bin/env bash
set -euo pipefail

echo "=== ANTHONYWARE IDENTITY STACK INSTALLER ==="

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

# Allow override via env, otherwise default to anthonyware in the target user's home
REPO="${REPO:-$TARGET_HOME/anthonyware}"

echo "Running as user: $TARGET_USER"
echo "Target home: $TARGET_HOME"
echo "Using repo: $REPO"

# Hard‑refuse if run as pure root without SUDO_USER
if [ "$TARGET_USER" = "root" ]; then
    echo "ERROR: Do not run this installer as pure root."
    echo "Run it as your normal user with: sudo ./scripts/install-all.sh"
    exit 1
fi

# Idempotency guard
if [ -f "$TARGET_HOME/.anthonyware-installed" ]; then
    echo "Anthonyware identity stack already installed."
    echo "Remove $TARGET_HOME/.anthonyware-installed to reinstall."
    exit 0
fi

# ---------------------------------------------------------
# 0. Ensure repo exists
# ---------------------------------------------------------
if [ ! -d "$REPO" ]; then
    echo "Repository not found at $REPO"
    exit 1
fi

# ---------------------------------------------------------
# 0.5 Preflight checks
# ---------------------------------------------------------
echo "[0/10] Running preflight checks..."

required_cmds=( pacman cp sed mkdir )
for cmd in "${required_cmds[@]}"; do
    if ! command -v "$cmd" >/dev/null; then
        echo "ERROR: Required command '$cmd' not found. Install it before running this script."
        exit 1
    fi
done

optional_cmds=( grub-mkconfig mkinitcpio modinfo jq hyprlock )
for cmd in "${optional_cmds[@]}"; do
    if ! command -v "$cmd" >/dev/null; then
        echo "WARNING: Optional tool '$cmd' not found. Some features may be skipped."
    fi
done

# Helper: ensure dir exists and report writability
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        sudo mkdir -p "$dir" || { echo "ERROR: Cannot create $dir"; exit 1; }
    fi
    if [ ! -w "$dir" ]; then
        echo "NOTE: Directory $dir is not writable by current user; operations will use sudo where necessary."
    fi
}

# ---------------------------------------------------------
# 1. Install required packages
# ---------------------------------------------------------
echo "[1/10] Updating system package database..."

sudo pacman -Syu --noconfirm || {
    echo "WARNING: pacman -Syu failed. You may need to resolve mirror or key issues manually."
}

# Check that required packages exist in official repos before attempting to install
echo "[1/10] Checking package availability..."

packages=(
    sddm qt6-quickcontrols2 qt6-svg
    plymouth cava kitty waybar
)

for pkg in "${packages[@]}"; do
    if ! pacman -Si "$pkg" >/dev/null 2>&1; then
        echo "ERROR: Package '$pkg' not found in official repos."
        echo "Install it manually or adjust the package list."
        exit 1
    fi
done

# Detect likely AUR packages and warn
aur_packages=(
    eww-wayland
    swaync
    jetbrains-mono-nerd
)

for pkg in "${aur_packages[@]}"; do
    if ! pacman -Si "$pkg" >/dev/null 2>&1; then
        echo "NOTICE: '$pkg' appears to be an AUR package."
        echo "Install it manually with your AUR helper before running this script."
    fi
done

echo "[1/10] Installing required packages..."

sudo pacman -S --noconfirm --needed \
    sddm qt6-quickcontrols2 qt6-svg \
    plymouth \
    cava \
    kitty \
    waybar || {
        echo "ERROR: One or more core packages failed to install. Check pacman output."
        exit 1
    }

# Optional / AUR‑ish stuff (comment or handle separately later):
# eww-wayland
# swaync
# jetbrains-mono-nerd

# ---------------------------------------------------------
# 2. Create config directories
# ---------------------------------------------------------
echo "[2/10] Creating config directories..."

ensure_dir "$TARGET_HOME/.config/kitty"
ensure_dir "$TARGET_HOME/.config/fastfetch"
ensure_dir "$TARGET_HOME/.config/sddm"
ensure_dir "$TARGET_HOME/.config/hyprlock"
ensure_dir "$TARGET_HOME/.config/hypridle"
ensure_dir "$TARGET_HOME/.config/plymouth"
ensure_dir "$TARGET_HOME/.config/waybar"
ensure_dir "$TARGET_HOME/.config/cava"
ensure_dir "$TARGET_HOME/.config/eww"
ensure_dir "$TARGET_HOME/.config/swaync"
ensure_dir "$TARGET_HOME/.config/kitty/colors"

# ---------------------------------------------------------
# 3. Deploy system-wide palette
# ---------------------------------------------------------
echo "[3/10] Deploying color palette..."

if [ -f "$REPO/configs/colors/palette.conf" ]; then
    cp "$REPO/configs/colors/palette.conf" "$TARGET_HOME/.config/kitty/colors/palette.conf"
    sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/kitty/colors/palette.conf" || true
else
    echo "WARNING: palette.conf not found in $REPO/configs/colors"
fi

# ---------------------------------------------------------
# 4. Deploy Kitty theme engine
# ---------------------------------------------------------
echo "[4/10] Installing Kitty theme engine..."

if [ -f "$REPO/configs/kitty/kitty.conf" ]; then
    cp "$REPO/configs/kitty/kitty.conf" "$TARGET_HOME/.config/kitty/"
    sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/kitty/kitty.conf" || true
else
    echo "WARNING: kitty.conf not found in $REPO/configs/kitty"
fi

shopt -s nullglob

kitty_scripts=( "$REPO/configs/kitty/"*.sh )
kitty_colors=( "$REPO/configs/kitty/colors/"*.conf )

if (( ${#kitty_scripts[@]} )); then
    cp "${kitty_scripts[@]}" "$TARGET_HOME/.config/kitty/"
    if [ "$(id -u)" -eq 0 ]; then
        sudo chmod +x "$TARGET_HOME/.config/kitty/"*.sh
        sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/kitty/"*.sh || true
    else
        chmod +x "$TARGET_HOME/.config/kitty/"*.sh
    fi
else
    echo "WARNING: No Kitty scripts found in $REPO/configs/kitty/*.sh"
fi

if (( ${#kitty_colors[@]} )); then
    cp "${kitty_colors[@]}" "$TARGET_HOME/.config/kitty/colors/"
    sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/kitty/colors/"*.conf || true
else
    echo "WARNING: No Kitty color configs found in $REPO/configs/kitty/colors/*.conf"
fi

shopt -u nullglob

# Set night mode as default
if [ -x "$TARGET_HOME/.config/kitty/switch-theme.sh" ]; then
    sudo -u "$TARGET_USER" "$TARGET_HOME/.config/kitty/switch-theme.sh" anthonyware-night
else
    echo "WARNING: Kitty switch-theme.sh not found or not executable; skipping theme switch"
fi

# ---------------------------------------------------------
# 5. Deploy Fastfetch identity
# ---------------------------------------------------------
echo "[5/10] Installing Fastfetch identity..."

mkdir -p "$TARGET_HOME/.config/fastfetch"

if [ -f "$REPO/configs/fastfetch/fastfetch.jsonc" ]; then
    cp "$REPO/configs/fastfetch/fastfetch.jsonc" "$TARGET_HOME/.config/fastfetch/config.jsonc"
fi
if [ -f "$REPO/configs/fastfetch/ascii-a.txt" ]; then
    cp "$REPO/configs/fastfetch/ascii-a.txt" "$TARGET_HOME/.config/fastfetch/ascii-a.txt"
fi
if [ -f "$REPO/configs/fastfetch/greeting.sh" ]; then
    cp "$REPO/configs/fastfetch/greeting.sh" "$TARGET_HOME/.config/fastfetch/greeting.sh"
fi
if [ -f "$REPO/configs/fastfetch/health.sh" ]; then
    cp "$REPO/configs/fastfetch/health.sh" "$TARGET_HOME/.config/fastfetch/health.sh"
fi

if [ "$(id -u)" -eq 0 ]; then
    sudo chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/fastfetch" || true
    sudo chmod +x "$TARGET_HOME/.config/fastfetch/"*.sh || true
else
    chmod +x "$TARGET_HOME/.config/fastfetch/"*.sh || true
fi

# ---------------------------------------------------------
# 6. Deploy SDDM theme
# ---------------------------------------------------------
echo "[6/10] Installing SDDM theme..."

ensure_dir /usr/share/sddm/themes/anthonyware
sudo cp -r "$REPO/configs/sddm/theme/anthonyware/"* /usr/share/sddm/themes/anthonyware/

# Validate SDDM theme metadata
sddm_meta="/usr/share/sddm/themes/anthonyware/metadata.desktop"
if [ ! -f "$sddm_meta" ]; then
    echo "ERROR: SDDM theme metadata missing: $sddm_meta"
    exit 1
fi

echo "[6/10] Configuring SDDM theme..."

if [ -f /etc/sddm.conf ]; then
    sudo cp /etc/sddm.conf /etc/sddm.conf.anthonyware.bak
fi

if grep -q '^\[Theme\]' /etc/sddm.conf 2>/dev/null; then
    # Try to replace Current= value; if it does not exist add it under [Theme]
    sudo sed -i 's/^Current=.*/Current=anthonyware/' /etc/sddm.conf || true
    if ! grep -q '^Current=anthonyware' /etc/sddm.conf; then
        sudo sed -i '/^\[Theme\]/a Current=anthonyware' /etc/sddm.conf
    fi
else
    printf '[Theme]\nCurrent=anthonyware\n' | sudo tee -a /etc/sddm.conf >/dev/null
fi

sudo systemctl enable sddm

# ---------------------------------------------------------
# 7. Deploy Hyprlock + Hypridle
# ---------------------------------------------------------
echo "[7/10] Installing Hyprlock + Hypridle..."

mkdir -p "$TARGET_HOME/.config/hyprlock"
mkdir -p "$TARGET_HOME/.config/hypridle"

shopt -s nullglob
hyprlock_files=( "$REPO/configs/hyprlock/"* )
if (( ${#hyprlock_files[@]} )); then
    cp "${hyprlock_files[@]}" "$TARGET_HOME/.config/hyprlock/"
    sudo chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/hyprlock" || true
else
    echo "WARNING: No hyprlock assets found in $REPO/configs/hyprlock"
fi

if [ -f "$REPO/configs/hypridle/hypridle.conf" ]; then
    cp "$REPO/configs/hypridle/hypridle.conf" "$TARGET_HOME/.config/hypridle/"
    sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/hypridle/hypridle.conf" || true
else
    echo "WARNING: hypridle.conf not found in $REPO/configs/hypridle"
fi
shopt -u nullglob

# Validate hyprlock config if the validator is available
if command -v hyprlock >/dev/null 2>&1; then
    if ! hyprlock --validate >/dev/null 2>&1; then
        echo "WARNING: Hyprlock config validation failed."
    fi
fi

# ---------------------------------------------------------
# 8. Deploy Plymouth theme
# ---------------------------------------------------------
echo "[8/10] Installing Plymouth theme..."

ensure_dir /usr/share/plymouth/themes/anthonyware
shopt -s nullglob
plymouth_files=( "$REPO/configs/plymouth/anthonyware/"* )
if (( ${#plymouth_files[@]} )); then
    sudo cp "${plymouth_files[@]}" /usr/share/plymouth/themes/anthonyware/
else
    echo "WARNING: No Plymouth theme files found in $REPO/configs/plymouth/anthonyware"
fi
shopt -u nullglob

# Validate Plymouth metadata
plymouth_file="/usr/share/plymouth/themes/anthonyware/anthonyware.plymouth"
if [ ! -f "$plymouth_file" ]; then
    echo "ERROR: Plymouth theme metadata missing: $plymouth_file"
    echo "Theme may not load correctly."
    exit 1
fi
if ! grep -q "Name=" "$plymouth_file"; then
    echo "WARNING: Plymouth theme missing Name= field."
fi

echo "[8/10] Patching mkinitcpio HOOKS for plymouth..."

if ! command -v mkinitcpio >/dev/null; then
    echo "mkinitcpio not found; skipping initramfs regeneration."
else
    if [ ! -f /etc/mkinitcpio.conf ]; then
        echo "WARNING: /etc/mkinitcpio.conf not found; skipping HOOKS modification."
    else
        if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
            sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.anthonyware.bak
            sudo sed -E -i 's/^(HOOKS=\()([^\)]*)(\))/\1\2 plymouth\3/' /etc/mkinitcpio.conf
            echo "Inserted plymouth into HOOKS (backup: /etc/mkinitcpio.conf.anthonyware.bak)"
        else
            echo "plymouth already present in HOOKS; leaving as is."
        fi
        sudo mkinitcpio -P || { echo "ERROR: mkinitcpio failed; check your HOOKS and kernel config."; exit 1; }
    fi
fi

echo "[8/10] Patching GRUB kernel command line for plymouth..."

if command -v grub-mkconfig >/dev/null && [ -f /etc/default/grub ]; then
    sudo cp /etc/default/grub /etc/default/grub.anthonyware.bak

    if ! grep -q 'plymouth.enable=1' /etc/default/grub; then
        sudo sed -i -E 's/^(GRUB_CMDLINE_LINUX=")(.*)"/\1\2 quiet splash plymouth.enable=1"/' /etc/default/grub
        echo "Added plymouth.enable=1 to GRUB_CMDLINE_LINUX (backup: /etc/default/grub.anthonyware.bak)"
    else
        echo "plymouth.enable=1 already present in GRUB_CMDLINE_LINUX; leaving as is."
    fi

    sudo grub-mkconfig -o /boot/grub/grub.cfg || { echo "ERROR: grub-mkconfig failed; check /etc/default/grub."; exit 1; }
else
    echo "GRUB not detected (no grub-mkconfig or /etc/default/grub); skipping GRUB config generation."
fi

# ---------------------------------------------------------
# 9. Deploy Waybar + Cava + Eww visualizer
# ---------------------------------------------------------
echo "[9/10] Installing Waybar + Cava + Eww visualizer..."

# Waybar
if [ -f "$REPO/configs/waybar/config.jsonc" ]; then
    cp "$REPO/configs/waybar/config.jsonc" "$TARGET_HOME/.config/waybar/"
    sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/waybar/config.jsonc" || true
else
    echo "WARNING: waybar config.jsonc not found in $REPO/configs/waybar"
fi
if [ -f "$REPO/configs/waybar/style.css" ]; then
    cp "$REPO/configs/waybar/style.css" "$TARGET_HOME/.config/waybar/"
    sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/waybar/style.css" || true
fi

# Validate Waybar JSON if possible
if command -v jq >/dev/null 2>&1; then
    if ! jq empty "$TARGET_HOME/.config/waybar/config.jsonc" >/dev/null 2>&1; then
        echo "ERROR: Waybar config.jsonc is not valid JSON."
        exit 1
    fi
else
    echo "WARNING: 'jq' not found; skipping Waybar JSON validation."
fi

# Cava
if [ -f "$REPO/configs/cava/config" ]; then
    cp "$REPO/configs/cava/config" "$TARGET_HOME/.config/cava/config"
    sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/cava/config" || true
else
    echo "WARNING: cava config not found in $REPO/configs/cava"
fi

# Eww
shopt -s nullglob
eww_files=( "$REPO/configs/eww/"* )
if (( ${#eww_files[@]} )); then
    cp "${eww_files[@]}" "$TARGET_HOME/.config/eww/"
    sudo chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/eww" || true
else
    echo "WARNING: No Eww configuration found in $REPO/configs/eww"
fi
shopt -u nullglob

# ---------------------------------------------------------
# 10. Deploy SwayNC theme loader
# ---------------------------------------------------------
echo "[10/10] Installing SwayNC theme loader..."

cp "$REPO/configs/swaync/theme-loader.sh" "$TARGET_HOME/.config/swaync/theme-loader.sh"
if [ "$(id -u)" -eq 0 ]; then
    sudo chmod +x "$TARGET_HOME/.config/swaync/theme-loader.sh"
    sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/swaync/theme-loader.sh" || true
else
    chmod +x "$TARGET_HOME/.config/swaync/theme-loader.sh"
fi

# Validate swaync theme loader
if [ ! -x "$TARGET_HOME/.config/swaync/theme-loader.sh" ]; then
    echo "ERROR: SwayNC theme loader missing or not executable."
    exit 1
fi

sudo -u "$TARGET_USER" "$TARGET_HOME/.config/swaync/theme-loader.sh"

echo "=== ANTHONYWARE IDENTITY STACK INSTALLED SUCCESSFULLY ==="

# Mark as installed (idempotency)
if [ "$(id -u)" -eq 0 ]; then
    sudo touch "$TARGET_HOME/.anthonyware-installed"
    sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.anthonyware-installed" || true
else
    touch "$TARGET_HOME/.anthonyware-installed"
fi

echo "Reboot to activate Plymouth + SDDM + full identity chain."
