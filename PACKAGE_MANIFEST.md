# ANTHONYWARE PACKAGE MANIFEST

Master Package Checklist — All 260+ Packages

---

## HOW TO USE THIS MANIFEST

This is a **definitive record** of every package that should be in the Anthonyware installation system. Use it to:

1. ✅ **Validate** that nothing is missing
2. ✅ **Audit** any future changes
3. ✅ **Plan** new features
4. ✅ **Document** dependencies

---

## PACMAN PACKAGES (OFFICIAL REPOS)

### Core System

- [ ] base
- [ ] base-devel
- [ ] linux
- [ ] linux-firmware
- [ ] linux-headers
- [ ] amd-ucode
- [ ] intel-ucode
- [ ] sudo
- [ ] bash-completion
- [ ] man-db
- [ ] man-pages
- [ ] which

### System Utils

- [ ] tree
- [ ] zip
- [ ] unzip
- [ ] p7zip
- [ ] rsync
- [ ] htop
- [ ] btop
- [ ] tmux
- [ ] lsof
- [ ] strace
- [ ] ncdu
- [ ] duf
- [ ] tldr
- [ ] jq
- [ ] yq
- [ ] wget
- [ ] curl
- [ ] tar
- [ ] reflector
- [ ] xdg-user-dirs
- [ ] xdg-utils
- [ ] xdg-desktop-portal
- [ ] xdg-desktop-portal-gtk

### Networking

- [ ] networkmanager
- [ ] network-manager-applet
- [ ] plasma-nm
- [ ] openssh
- [ ] bind
- [ ] net-tools
- [ ] traceroute
- [ ] iperf3
- [ ] nmap
- [ ] tcpdump
- [ ] wireshark-qt
- [ ] tailscale
- [ ] cockpit
- [ ] samba
- [ ] samba-client
- [ ] samba-common
- [ ] nfs-utils
- [ ] avahi
- [ ] nss-mdns

### GPU & Graphics

- [ ] mesa
- [ ] vulkan-radeon
- [ ] libva-mesa-driver
- [ ] mesa-vdpau
- [ ] xf86-video-amdgpu
- [ ] nvidia
- [ ] nvidia-utils
- [ ] nvidia-settings
- [ ] dkms
- [ ] intel-media-driver
- [ ] vulkan-intel
- [ ] vulkan-tools
- [ ] nvtop
- [ ] radeontop
- [ ] xorg-server
- [ ] xorg-xauth
- [ ] xorg-xrandr
- [ ] xorg-xset
- [ ] xorg-xinput
- [ ] xorg-xwayland
- [ ] wayland

### Qt6 Runtime (FULL)

- [ ] qt6-base
- [ ] qt6-declarative
- [ ] qt6-quickcontrols2
- [ ] qt6-svg
- [ ] qt6-shadertools
- [ ] qt6-tools
- [ ] qt6-5compat
- [ ] qt6-languageserver
- [ ] qt6-multimedia

### Display Manager

- [ ] sddm

### Hyprland Desktop

- [ ] hyprland
- [ ] waybar
- [ ] wofi
- [ ] kitty
- [ ] mako
- [ ] hyprpaper
- [ ] hyprlock
- [ ] hypridle
- [ ] swww
- [ ] grim
- [ ] slurp
- [ ] swappy
- [ ] wl-clipboard
- [ ] cliphist
- [ ] wlogout
- [ ] polkit-kde-agent
- [ ] qt5-wayland
- [ ] qt6-wayland
- [ ] xdg-desktop-portal-hyprland
- [ ] wlr-randr

### Daily Driver Apps

- [ ] dolphin
- [ ] dolphin-plugins
- [ ] kio-extras
- [ ] ark
- [ ] vlc
- [ ] gimp
- [ ] obs-studio
- [ ] pavucontrol
- [ ] blueman
- [ ] kdeconnect
- [ ] solaar
- [ ] filelight
- [ ] qbittorrent
- [ ] libreoffice-fresh
- [ ] flatpak
- [ ] discover

### Development Tools

- [ ] git
- [ ] git-delta
- [ ] cmake
- [ ] ninja
- [ ] make
- [ ] gcc
- [ ] clang
- [ ] gdb
- [ ] valgrind
- [ ] python
- [ ] python-pip
- [ ] python-virtualenv
- [ ] nodejs
- [ ] npm
- [ ] go
- [ ] rustup
- [ ] jdk-openjdk
- [ ] docker
- [ ] docker-compose
- [ ] zsh
- [ ] starship
- [ ] neovim
- [ ] kate
- [ ] zoxide
- [ ] atuin
- [ ] broot
- [ ] yazi
- [ ] fd
- [ ] ripgrep
- [ ] bat
- [ ] eza
- [ ] fzf

### AI/ML (Pacman side)

- [ ] python-numpy
- [ ] python-scipy
- [ ] python-pandas
- [ ] python-matplotlib
- [ ] python-scikit-learn
- [ ] python-jupyterlab
- [ ] python-seaborn
- [ ] python-tqdm
- [ ] python-requests
- [ ] python-ipykernel
- [ ] python-nbformat
- [ ] python-nbconvert
- [ ] python-jupyterlab_server
- [ ] python-ipywidgets

### CAD / CNC / 3D Printing

- [ ] blender
- [ ] kicad
- [ ] freecad
- [ ] openscad
- [ ] prusa-slicer
- [ ] octoprint

### Electrical Engineering / FPGA

- [ ] ngspice
- [ ] qucs-s
- [ ] sigrok-cli
- [ ] pulseview
- [ ] arduino-cli
- [ ] openocd
- [ ] avrdude
- [ ] dfu-util
- [ ] arm-none-eabi-gcc
- [ ] octave
- [ ] gnuplot
- [ ] python-usbtmc
- [ ] yosys
- [ ] nextpnr
- [ ] iverilog
- [ ] gtkwave

### Hardware Support

- [ ] spacenavd
- [ ] libspnav
- [ ] x11-spnav
- [ ] piper
- [ ] ratbagd
- [ ] ltunify
- [ ] lm_sensors
- [ ] psensor
- [ ] thermald

### Security

- [ ] firewalld
- [ ] apparmor
- [ ] apparmor-parser
- [ ] firejail
- [ ] firetools
- [ ] fail2ban
- [ ] usbguard
- [ ] keepassxc
- [ ] veracrypt
- [ ] gnupg
- [ ] age

### Backups

- [ ] timeshift
- [ ] timeshift-autosnap
- [ ] btrfs-progs
- [ ] snapper
- [ ] grub-btrfs
- [ ] borgbackup
- [ ] vorta
- [ ] syncthing
- [ ] restic
- [ ] rclone

### Webcam / Media

- [ ] v4l-utils
- [ ] ffmpeg
- [ ] cheese
- [ ] guvcview

### Virtualization & VFIO

- [ ] qemu-full
- [ ] virt-manager
- [ ] virt-viewer
- [ ] dnsmasq
- [ ] bridge-utils
- [ ] openbsd-netcat
- [ ] iptables-nft
- [ ] edk2-ovmf
- [ ] swtpm
- [ ] libvirt
- [ ] virtio-win
- [ ] qemu-guest-agent
- [ ] spice-vdagent

### Printing

- [ ] cups
- [ ] cups-pdf
- [ ] system-config-printer
- [ ] ghostscript
- [ ] gsfonts
- [ ] foomatic-db-engine
- [ ] foomatic-db
- [ ] foomatic-db-ppds
- [ ] gutenprint

### Fonts & Icons

- [ ] noto-fonts
- [ ] noto-fonts-extra
- [ ] noto-fonts-emoji
- [ ] noto-fonts-cjk
- [ ] ttf-dejavu
- [ ] ttf-liberation
- [ ] ttf-jetbrains-mono
- [ ] ttf-fira-code
- [ ] ttf-nerd-fonts-symbols
- [ ] papirus-icon-theme

### Audio

- [ ] pipewire
- [ ] pipewire-alsa
- [ ] pipewire-pulse
- [ ] pipewire-jack
- [ ] wireplumber
- [ ] helvum

### Power & Firmware

- [ ] tlp
- [ ] tlp-rdw
- [ ] powertop
- [ ] auto-cpufreq
- [ ] thermald
- [ ] fwupd

### Diagnostics

- [ ] smartmontools
- [ ] nvme-cli
- [ ] memtest86+
- [ ] kdump

### LaTeX & Docs

- [ ] texlive-most
- [ ] biber
- [ ] pandoc
- [ ] zathura
- [ ] zathura-pdf-mupdf

### Color Management

- [ ] colord
- [ ] gnome-color-manager
- [ ] argyllcms

### Wayland Recording

- [ ] wf-recorder
- [ ] obs-vkcapture

### XWayland Legacy

- [ ] xorg-xwayland
- [ ] xclip
- [ ] xdotool
- [ ] xorg-xlsclients

---

## AUR PACKAGES (38 TOTAL)

### Display & Desktop

- [ ] eww-wayland
- [ ] swaync
- [ ] grimblast-git
- [ ] hyprpicker
- [ ] wdisplays

### Fonts & Nerd Fonts

- [ ] ttf-jetbrains-mono-nerd
- [ ] ttf-firacode-nerd
- [ ] visual-studio-code-bin

### CAD & 3D Printing

- [ ] fusion360-bin
- [ ] candle
- [ ] universal-gcode-sender-bin
- [ ] bcnc
- [ ] openbuilds-control-bin
- [ ] lasergrbl-bin
- [ ] cura-bin
- [ ] lychee-slicer-bin
- [ ] mainsail
- [ ] fluidd

### Hardware Support (AUR)

- [ ] spnavcfg
- [ ] alienfx
- [ ] awcc-linux
- [ ] dell-bios-fan-control
- [ ] nbfc-linux

### Color Management (AUR)

- [ ] displaycal

### Electrical Engineering

- [ ] ltspice
- [ ] scpi-tools

### Instrumentation

- [ ] scpi-tools (duplicate for documentation)

### Virtualization

- [ ] looking-glass-client

### Audio (AUR)

- [ ] qpwgraph

### AI/ML

- [ ] text-generation-webui
- [ ] koboldcpp
- [ ] llama.cpp
- [ ] oobabooga

### Fusion 360 Runtime

- [ ] vkd3d-proton
- [ ] dxvk-bin

---

## PIP PACKAGES (22 TOTAL)

### PyTorch & TensorFlow

- [ ] torch (CUDA wheel)
- [ ] torchvision
- [ ] torchaudio
- [ ] tensorflow==2.15
- [ ] tensorflow-io-gcs-filesystem

### HuggingFace & LLMs

- [ ] transformers
- [ ] accelerate
- [ ] datasets
- [ ] tokenizers
- [ ] bitsandbytes
- [ ] optimum
- [ ] onnxruntime-gpu
- [ ] deepspeed
- [ ] flash-attn
- [ ] sentencepiece

### Jupyter Ecosystem

- [ ] jupyterlab-lsp
- [ ] python-lsp-server
- [ ] jupyterlab-git
- [ ] jupyterlab-variableinspector
- [ ] jupyterlab-code-formatter
- [ ] jupyterlab_execute_time
- [ ] jupyter_http_over_ws

---

## INSTALLATION SCRIPTS (38 TOTAL)

- [ ] 00-preflight-checks.sh
- [ ] 01-base-system.sh
- [ ] 02-qt6-runtime.sh ⭐ NEW
- [ ] 03-hyprland.sh
- [ ] 04-daily-driver.sh
- [ ] 05-dev-tools.sh
- [ ] 06-ai-ml.sh
- [ ] 07-cad-cnc-3dprinting.sh
- [ ] 08-hardware-support.sh
- [ ] 09-security.sh
- [ ] 10-backups.sh
- [ ] 10-webcam-media.sh ⭐ NEW
- [ ] 11-vfio-windows-vm.sh
- [ ] 12-printing.sh
- [ ] 13-fonts.sh
- [ ] 14-portals.sh
- [ ] 15-power-management.sh
- [ ] 16-firmware.sh
- [ ] 17-steam.sh
- [ ] 18-networking-tools.sh
- [ ] 19-electrical-engineering.sh
- [ ] 20-fpga-toolchain.sh
- [ ] 21-instrumentation.sh
- [ ] 22-homelab-tools.sh
- [ ] 23-terminal-qol.sh
- [ ] 24-cleanup-and-verify.sh
- [ ] 25-color-management.sh
- [ ] 26-archive-tools.sh
- [ ] 27-zram-swap.sh
- [ ] 28-audio-routing.sh
- [ ] 29-misc-utilities.sh
- [ ] 30-finalize.sh
- [ ] 31-wayland-recording.sh
- [ ] 32-latex-docs.sh ⭐ NEW
- [ ] 33-cleaner.sh
- [ ] 34-diagnostics.sh ⭐ NEW
- [ ] 35-fusion360-runtime.sh ⭐ NEW
- [ ] 36-xwayland-legacy.sh
- [ ] 99-update-everything.sh

---

## SPECIAL CONFIGURATION FILES

- [ ] /etc/sddm.conf.d/10-qt6-env.conf (created by 02-qt6-runtime.sh)

---

## KEY STATISTICS

| Item | Count |
| ------ | ------- |
| Pacman Packages | 200+ |
| AUR Packages | 38 |
| Pip Packages | 22 |
| Install Scripts | 38 |
| **TOTAL** | **260+** |

---

## VERIFICATION CHECKLIST

Use this to confirm everything is installed:

```bash
# Check all pacman packages (example)
for pkg in python-ipykernel python-nbformat qt6-base wlr-randr; do
  pacman -Q "$pkg" || echo "MISSING: $pkg"
done

# Check all AUR packages (example)
for pkg in wdisplays jupyterlab-git fusion360-bin; do
  pacman -Q "$pkg" || echo "MISSING (AUR): $pkg"
done

# Check pip packages (example)
for pkg in jupyterlab-lsp jupyter-git torch tensorflow; do
  python -c "import $pkg" || echo "MISSING (pip): $pkg"
done

# Verify all scripts in run-all.sh
wc -l install/run-all.sh  # Should have ~48 lines (38 scripts + header)
```

---

## NOTES

1. **Duplicates are intentional** — Some packages appear in multiple scripts for clarity and idempotency.
2. **--needed flag** — All pacman/yay commands use `--needed`, so re-runs are safe.
3. **Optional warnings** — Some AUR packages may fail gracefully if yay is not installed.
4. **Pip wheels** — PyTorch uses CUDA wheels (`--index-url https://download.pytorch.org/whl/cu121`).

---

Last Updated: January 14, 2026
