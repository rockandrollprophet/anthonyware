# 🚀 Anthonyware OS — Quick Install Guide

## Boot to Arch ISO and Run

```bash
# 1. Boot Arch Linux ISO (download from archlinux.org)
# 2. Connect to internet

# WiFi:
iwctl
# [iwctl]# device list
# [iwctl]# station wlan0 scan
# [iwctl]# station wlan0 get-networks
# [iwctl]# station wlan0 connect "YOUR_SSID"
# [iwctl]# exit

# OR Ethernet (usually auto-connects):
ip link

# 3. Install git
pacman -Sy git

# 4. Clone repo
git clone https://github.com/rockandrollprophet/anthonyware /root/anthonyware
cd /root/anthonyware

# 5. Run pre-install check
chmod +x pre-install-check.sh
sudo ./pre-install-check.sh

# 6. If all checks pass, run installer
chmod +x install-anthonyware.sh
sudo ./install-anthonyware.sh

# 7. Follow prompts and answer:
#    - Disk: /dev/nvme0n1 (or /dev/sda for SATA)
#    - Hostname: anthonyware (or your choice)
#    - Username: (enter your desired login name)
#    - User Password: (with confirmation)
#    - Root Password: (with confirmation)
#    - Repository URL: (leave default or customize)

# 8. System will install, then reboot
# 9. Login and enjoy!
```

## What You'll Be Asked

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
