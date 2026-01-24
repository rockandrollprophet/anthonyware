# 🚀 Anthonyware OS — Quick Install Guide

## Phase 1: Base System (5-10 min)

```bash
# 1. Boot Arch Linux ISO
# 2. Connect to network
iwctl  # for WiFi
# OR use ethernet (auto-connects)

# 3. Navigate to anthonyware on USB
lsblk  # find your USB
mount /dev/sdX1 /mnt
cd /mnt/anthonyware

# 4. Run base installer
bash install-anthonyware.sh
# Prompts: disk, hostname, timezone, locale (NO username/password)
# Installs base Arch + GRUB, then reboots
```

## Phase 2: User Setup (2 min)

```bash
# 1. After reboot, press Ctrl+Alt+F2 for root shell
# 2. Run user creation script
cd /root/anthonyware-setup/anthonyware/install
bash 00-create-user.sh
# Prompts: username, user password, root password
# Configures sudo automatically
```

## Phase 3: Full Install (45-60 min)

```bash
# 1. Logout and login as your new user
# 2. Run installation pipeline
sudo CONFIRM_INSTALL=YES \
     TARGET_USER="youruser" \
     TARGET_HOME="/home/youruser" \
     REPO_PATH="/root/anthonyware-setup/anthonyware" \
     bash /root/anthonyware-setup/anthonyware/install/run-all.sh

# 3. Pipeline installs 260+ packages
# 4. Reboot when complete
sudo reboot

# 5. Login at SDDM graphical screen, select Hyprland
```

## Critical Changes (2026-01-17)

✅ **SDDM now actually installed** (was missing!)  
✅ **User creation is manual** (not automated)  
✅ **Pipeline works before user exists**  
✅ **All scripts idempotent** (root or sudo)

See **INSTALLATION_FIXES_2026-01-17.md** for details.

## What Gets Installed

| Prompt | Default | Notes |
| -------- | --------- | ------- |
| Target disk | `/dev/nvme0n1` | ⚠️ Will be WIPED |
| Hostname | `anthonyware` | Computer name |
| Username | (required) | Your login name |
| User password | (required) | For login and sudo |
| Root password | (required) | For root account |
| Repository URL | `rockandrollprophet/anthonyware` | Can customize |

## After First Boot

```bash
# Run welcome wizard
~/anthonyware/scripts/welcome.sh

# Check system health
~/anthonyware/scripts/health-dashboard.sh

# Validate everything installed correctly
cd ~/anthonyware/install
bash 35-validation.sh
```

## Minimum Requirements

- **Disk**: 30GB free space
- **RAM**: 4GB minimum (8GB recommended)
- **CPU**: x86_64 with virtualization support
- **Boot**: UEFI preferred (BIOS works)
- **Network**: Internet connection required

## Troubleshooting

**No internet?**

```bash
ping archlinux.org
# If fails, reconnect WiFi with iwctl
```

**Wrong disk?**

```bash
lsblk  # List all disks
# Then specify: sudo ./install-anthonyware.sh
# (script will prompt for disk)
```

**Installation failed?**

```bash
# Check logs
tail ~/anthonyware-logs/*.log

# Try again
cd /root/anthonyware
sudo ./install-anthonyware.sh
```

---

**Full documentation**: See `INSTALLATION_GUIDE.md` for detailed instructions.
