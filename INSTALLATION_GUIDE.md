# 🚀 Anthonyware OS 1.0 — Complete Installation Guide
---
## Engineering, Scientific, and CNC Tools: Package Selection

### ✔ KEEP/Add

blender
sympy (pip)
kicad
openscad
fusion360-bin
freecad
candle
universal-gcode-sender-bin
bcnc
openbuilds-control-bin
lasergrbl-bin
prusa-slicer
cura-bin
lychee-slicer-bin
octoprint
mainsail
fluidd
meshlab
cloudcompare
ngspice
gerbv
sigrok-cli
pulseview
arduino-cli
openocd
avrdude
dfu-util
arm-none-eabi-gcc
arm-none-eabi-gdb
python-usbtmc
python-pyvisa
octave
octave-control
octave-signal
gnuplot
scpi-tools
libsigrok
libsigrokdecode
python-shapely

### ❌ REMOVE

qucs-s
geda
pcb (AUR)
ltspice (AUR)
sigrok (AUR)

## Overview

**Anthonyware OS** is a fully automated, production-ready Arch Linux distribution with:

- **Complete provisioning** — From bare metal to fully configured system in one command
- **260+ packages** across pacman, AUR, and pip
- **38 installation scripts** in proper dependency order
- **Comprehensive validation** — All components verified after installation
- **Production diagnostics** — Health checks, config validation, snapshots
- **Full CI/CD** — GitHub Actions testing pipeline included

---

## Quick Start (TL;DR)

```bash
# Boot Arch Linux ISO
# Login as root

# Download and run the master installer
git clone https://github.com/YOURNAME/anthonyware /root/anthonyware
cd /root/anthonyware
sudo ./install-anthonyware.sh

# Follow the prompts
# Machine reboots into fully configured Anthonyware OS
```

---

## Prerequisites

### Hardware

- **Disk**: 30 GB minimum free space on `/dev/nvme0n1` (configurable)
- **RAM**: 8 GB recommended (4 GB minimum)
- **GPU**: NVIDIA, AMD, or Intel (auto-detected and configured)
- **Network**: Internet connectivity during installation

### Software

- **Arch Linux ISO** — Current version (bootable on USB)
- **Root access** — Required for system installation

---

## Installation Methods

### Method 1: Automated (Recommended)

This is the standard installation path. Use if you're starting from a fresh Arch Linux ISO.

#### Step 1: Boot and Connect

```bash
# Boot Arch ISO
# At the boot prompt, select "Arch Linux install medium"
# System boots to live environment

# Check network connectivity
ping arch.org

# If no network, use wifi-menu (deprecated) or iwctl:
iwctl
# [iwctl]# device list
# [iwctl]# station wlan0 connect SSID
# [iwctl]# exit
```

#### Step 2: Clone and Run

```bash
# Update pacman
pacman -Sy

# Install git
pacman -S --noconfirm git

# Clone Anthonyware
git clone https://github.com/YOURNAME/anthonyware /root/anthonyware

# Navigate to repo
cd /root/anthonyware

# Run installer
sudo ./install-anthonyware.sh
```

#### Step 3: Answer Prompts

```text
Target disk [/dev/nvme0n1]: 
Hostname [anthonyware]: 
Username [rockandrollprophet]: 
Timezone [America/New_York]: 
Repository URL [https://...]: 
```

#### Step 4: Confirm and Wait

- Type `YES` to confirm disk wipe
- Installation takes 45-90 minutes depending on internet speed
- System reboots automatically

#### Step 5: First Login

```bash
# Login with username you provided
# Password is what you set during installation

# Run first-boot wizard
./scripts/first-boot-wizard.sh
```

---

### Method 2: Manual Installation (Advanced)

If you want to manually partition or use a different disk layout:

#### Step 1: Manual Partitioning

```bash
# Identify your disk
lsblk

# Use cfdisk, fdisk, or gdisk to partition
# Minimum:
#   /dev/nvme0n1p1 = 512 MiB EFI (type ef00)
#   /dev/nvme0n1p2 = Rest of disk for Btrfs root (type 8300)
```

#### Step 2: Format and Mount

```bash
# Format EFI
mkfs.fat -F32 /dev/nvme0n1p1

# Format root
mkfs.btrfs -f /dev/nvme0n1p2

# Create subvolumes
mount /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@snapshots
umount /mnt

# Mount with compression
mount -o subvol=@,compress=zstd /dev/nvme0n1p2 /mnt
mkdir -p /mnt/{boot,home,var/{log,cache/pacman/pkg},.snapshots}
mount -o subvol=@home,compress=zstd /dev/nvme0n1p2 /mnt/home
mount -o subvol=@log,compress=zstd /dev/nvme0n1p2 /mnt/var/log
mount -o subvol=@pkg,compress=zstd /dev/nvme0n1p2 /mnt/var/cache/pacman/pkg
mount -o subvol=@snapshots,compress=zstd /dev/nvme0n1p2 /mnt/.snapshots
mount /dev/nvme0n1p1 /mnt/boot
```

#### Step 3: Base System

```bash
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers \
  networkmanager sudo git btrfs-progs grub efibootmgr
genfstab -U /mnt >> /mnt/etc/fstab
```

#### Step 4: Chroot and Run Installer Scripts

```bash
arch-chroot /mnt

# Inside chroot
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

# Clone repo
git clone https://github.com/YOURNAME/anthonyware /root/anthonyware
cd /root/anthonyware/install

# Create user
useradd -m -s /bin/bash rockandrollprophet
echo "rockandrollprophet:yourpassword" | chpasswd

# Set sudo
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
usermod -aG wheel,docker,libvirt rockandrollprophet

# Install GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Run installation pipeline
export TARGET_USER="rockandrollprophet"
export TARGET_HOME="/home/rockandrollprophet"
export REPO_PATH="/root/anthonyware"

sudo -u rockandrollprophet bash -c 'cd /root/anthonyware/install && TARGET_USER="$TARGET_USER" TARGET_HOME="$TARGET_HOME" REPO_PATH="$REPO_PATH" ./run-all.sh'

# Exit chroot
exit
```

---

## Post-Installation

### First Login

```bash
# System boots into Hyprland (Wayland compositor)
# Login with your username

# Run first-boot wizard
./scripts/first-boot-wizard.sh
```

### Essential First Steps

```bash
# 1. Change password
passwd

# 2. Check system health
health-dashboard

# 3. Review configuration
~/.config/hypr/hyprland.conf

# 4. Create baseline snapshot
create-baseline-snapshot.sh

# 5. Set up backups
backup-system
```

---

## System Architecture

### Installation Pipeline

```text
install-anthonyware.sh (master entrypoint)
    ↓
Disk partitioning (Btrfs with subvolumes)
    ↓
Arch Linux base system
    ↓
run-all.sh (orchestrator)
    ↓
38 installation scripts (sequential)
    ├─ 00-preflight-checks.sh
    ├─ 01-base-system.sh
    ├─ 02-qt6-runtime.sh (NEW)
    ├─ 03-hyprland.sh
    ├─ ...
    ├─ 33-user-configs.sh (NEW)
    ├─ 34-diagnostics.sh
    ├─ 35-validation.sh (NEW)
    └─ 99-update-everything.sh
    ↓
Validation (35-validation.sh)
    ↓
Diagnostics (health-dashboard.sh)
    ↓
Ready for use
```

### Directory Structure

```text
anthonyware/
├── install-anthonyware.sh    ← Master installer
├── install/                  ← Installation scripts
│   ├── 00-preflight-checks.sh
│   ├── 01-base-system.sh
│   ├── ...
│   ├── 33-user-configs.sh   ← NEW: User configs
│   ├── 35-validation.sh      ← NEW: Validation
│   └── run-all.sh            ← Orchestrator
├── scripts/                  ← Utility scripts
│   ├── health-dashboard.sh   ← System health check
│   ├── validate-configs.sh   ← Config validation
│   ├── welcome.sh            ← Welcome screen
│   ├── first-boot-wizard.sh  ← Setup wizard
│   ├── rollback-to-factory.sh
│   ├── create-baseline-snapshot.sh
│   └── rollback-configs.sh
├── configs/                  ← User configs
│   ├── hypr/
│   ├── hyprlock/
│   ├── waybar/
│   ├── kitty/
│   ├── fastfetch/
│   └── ...
├── docs/
├── .github/workflows/ci.yml  ← GitHub Actions
└── README.md
```

---

## Key Features

### 1. Automated Disk Setup

```bash
# Master installer handles:
✓ Disk partitioning (GPT/EFI)
✓ Btrfs subvolumes with compression
✓ Secure EFI boot configuration
✓ Proper mount options and fstab
```

### 2. Complete Package Management

**260+ packages** across three channels:

- **Pacman** (200+): Core system, desktop, development, AI/ML, CAD, electrical
- **AUR** (38): fonts, tools, CAD/CAM, firmware
- **Pip** (22): PyTorch, TensorFlow, Jupyter ecosystem

See `PACKAGE_MANIFEST.md` for complete list.

### 3. User Configuration Deployment

`install/33-user-configs.sh` deploys all configs:

```bash
✓ Hyprland (hypr/ → ~/.config/hypr/)
✓ Hyprlock (hyprlock/ → ~/.config/hyprlock/)
✓ Waybar (waybar/ → ~/.config/waybar/)
✓ Kitty (kitty/ → ~/.config/kitty/)
✓ Shell RC files (.zshrc, .bashrc)
✓ Proper ownership and permissions
```

### 4. Comprehensive Validation

`install/35-validation.sh` checks:

```bash
✓ SDDM / Qt6 configuration
✓ Hyprland and desktop environment
✓ GPU drivers (NVIDIA, AMD, Intel)
✓ PipeWire audio
✓ NetworkManager
✓ Docker, libvirtd
✓ Python ML stack
✓ CAD tools (Blender, FreeCAD, KiCAD)
✓ FPGA tools (Yosys, NextPNR)
✓ User configs present
✓ System files in place
```

### 5. Diagnostics and Health Checks

```bash
# Quick system health
$ health-dashboard

# Validate configs
$ validate-configs

# Create baseline snapshot
$ create-baseline-snapshot

# Restore from baseline
$ rollback-to-factory
```

### 6. CI/CD Pipeline

GitHub Actions (`,.github/workflows/ci.yml`) automatically:

```bash
✓ Lint all shell scripts (ShellCheck)
✓ Check bash syntax
✓ Validate JSON configs
✓ Verify script presence in run-all.sh
✓ Dry-run test in Arch container
✓ Verify package lists
✓ Validate documentation
```

---

## Troubleshooting

### Installation Fails

Check logs:

```bash
tail -f ~/anthonyware-logs/*.log
```

Common issues:

- **Network**: `ping arch.org` or check wifi
- **Disk space**: `df -h /` should show 30+ GB free
- **AUR packages**: Some may fail gracefully; non-critical

### After Installation

If something breaks:

```bash
# Restore baseline snapshot
$ rollback-to-factory

# Or restore individual config
$ rollback-configs
```

### GPU Issues

Check GPU detection:

```bash
lspci | grep -i "vga\|gpu\|3d"
nvidia-smi              # If NVIDIA
```

Install specific driver if needed:

```bash
sudo bash install/02-gpu-drivers.sh
```

### Hyprland Not Starting

```bash
# Check keyboard layout
setxkbmap us

# Try starting Hyprland manually
Hyprland

# Or check logs
journalctl -xe
```

---

## Configuration

### Customize Hyprland

Edit `~/.config/hypr/hyprland.conf`:

```bash
$EDITOR ~/.config/hypr/hyprland.conf

# Then reload:
hyprctl reload
```

### Customize Waybar

Edit `~/.config/waybar/config.jsonc` and `style.css`:

```bash
$EDITOR ~/.config/waybar/config.jsonc
$EDITOR ~/.config/waybar/style.css
```

### Add Custom Packages

Edit relevant script in `install/` and re-run:

```bash
# Add packages to 06-ai-ml.sh for example
sudo bash install/06-ai-ml.sh

# Or edit and run full pipeline with DRY_RUN
DRY_RUN=0 bash install/run-all.sh
```

---

## Advanced Usage

### Dry-Run Mode

Test installation without modifying system:

```bash
DRY_RUN=1 bash install/run-all.sh
```

This will:

- Skip `pacman -Syu` and package installs
- Skip config deployments
- Skip system modifications
- Report what WOULD have run

### Running Individual Scripts

Each script is standalone:

```bash
# Install just GPU drivers
sudo bash install/02-gpu-drivers.sh

# Install just AI/ML
sudo bash install/06-ai-ml.sh

# Deploy user configs
sudo bash install/33-user-configs.sh
```

### Custom Installation

```bash
# Clone repo to custom location
git clone https://github.com/YOURNAME/anthonyware /custom/path

# Run with environment variables
export TARGET_USER="myuser"
export TARGET_HOME="/home/myuser"
export REPO_PATH="/custom/path"

cd /custom/path/install
sudo bash run-all.sh
```

---

## What Gets Installed

### Desktop Environment

- **Hyprland** — Modern Wayland compositor
- **Waybar** — Status bar with custom modules
- **Kitty** — GPU-accelerated terminal
- **Hyprlock** — Wayland-native lock screen
- **Hypridle** — Idle management
- **SDDM** — Login manager with Qt6 theming

### Development

- **Languages**: Python, Node.js, Rust, Go, C/C++
- **Tools**: Git, VS Code, Neovim, Docker, QEMU/KVM
- **Build**: CMake, Ninja, Make, GCC, Clang

### AI/ML

- **PyTorch** with CUDA support (NVIDIA)
- **TensorFlow** with GPU acceleration
- **Jupyter Lab** with 12+ extensions
- **Data Science**: NumPy, Pandas, Scikit-learn, Matplotlib

### CAD/CAM/3D

- **Blender** — 3D modeling and rendering
- **FreeCAD** — CAD design
- **KiCAD** — PCB design
- **Prusa Slicer** — 3D print slicing
- **OpenSCAD** — Parametric 3D design

### Electrical Engineering

- **KiCAD** — PCB layout
- **ngspice** — Circuit simulation
- **Yosys** + **NextPNR** — FPGA synthesis
- **gtkwave** — Waveform viewer
- **Arduino CLI** — Microcontroller tools


### System Tools

- **Timeshift** — System snapshots
- **BorgBackup** — Encrypted backups
- **Syncthing** — File synchronization
- **Firewalld** — Firewall management
- **Tailscale** — VPN networking

---

## XDG Portals & Wayland Integration

**Installed Packages:**
- xdg-desktop-portal
- xdg-desktop-portal-hyprland
- xdg-desktop-portal-gtk
- xdg-desktop-portal-qt
- qt5-wayland
- qt6-wayland

All packages were installed or confirmed present using `yay --noconfirm --needed`.

**Notes:**
- Mirrorlist warnings were encountered ("directive 'Server' in section 'options' not recognized"), but these are non-fatal and do not affect package installation. Review your `/etc/pacman.d/mirrorlist` for syntax if desired, but no action is required for successful installs.

**Next Steps:**
- Proceed to the next group or review additional integration/configuration steps as needed.

---

## Performance Tuning
## Power Management

**Installed/Enabled:**
- tlp
- tlp-rdw
- thermald
- powertop
- power-profiles-daemon

**Removed/Uninstalled:**
- auto-cpufreq
- gnome-settings-daemon (not present)
- gsd-power (not present)

**Services Enabled:**
- tlp
- thermald

All changes applied using yay and systemctl. Mirrorlist warnings are non-fatal and can be ignored.

---
## Performance Tuning

### For AI/ML

```bash
# Check GPU VRAM
nvidia-smi

# Monitor during training
watch -n 0.1 nvidia-smi

# Use CUDA efficiently
export CUDA_VISIBLE_DEVICES=0
python your_training_script.py
```

### For CAD

```bash
# Blender with GPU rendering
blender --enable-autoexec

# FreeCAD performance
# Preferences → Display → Graphics Driver → OpenGL
```

### For Gaming

```bash
# Steam with Proton
steam

# Or set PROTON_LOG for debugging
PROTON_LOG=1 /usr/bin/steam
```

---

## Maintenance

### Regular Updates

```bash
# Full system update
bash scripts/update-everything.sh

# Or just pacman
sudo pacman -Syu
```

### Backup Strategy

```bash
# Create manual snapshot
create-baseline-snapshot

# Scheduled backups
sudo systemctl enable timeshift-autosnap-onboot

# Off-site backup
bash scripts/backup-system.sh
bash scripts/backup-home.sh
```

### Diagnostics

```bash
# System health
health-dashboard

# Config validation
validate-configs

# Disk health
smartctl -a /dev/nvme0n1

# Journal logs
journalctl -xe
```

---

## Support & Resources

### Documentation

- [QUICK_START.md](QUICK_START.md) — 30-second verification
- [docs/install-guide.md](docs/install-guide.md) — Installation details
- [PACKAGE_MANIFEST.md](PACKAGE_MANIFEST.md) — Complete package list
- [docs/first-boot-checklist.md](docs/first-boot-checklist.md) — Post-install setup

### If Something Breaks

1. Check logs: `tail -f ~/anthonyware-logs/*.log`
2. Validate configs: `validate-configs`
3. Run diagnostics: `health-dashboard`
4. Restore snapshot: `rollback-to-factory`
5. Restore config: `rollback-configs`

### GitHub Issues

For bugs or feature requests:
<https://github.com/YOURNAME/anthonyware/issues>

---

## License & Attribution

Anthonyware OS is provided as-is for personal and educational use.

Third-party software licenses apply:

- Arch Linux: GPL
- Hyprland: BSD-3-Clause
- Other tools: See their respective licenses

---

**Version**: 1.0  
**Last Updated**: January 14, 2026  
**Status**: Production Ready
