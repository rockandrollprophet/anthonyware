# Anthonyware OS - New Features Documentation

## January 2026 Major Update

This document describes all the new features and enhancements implemented in the Anthonyware OS installation system.

---

## ✨ New Features Summary

### 1. **Checkpoint & Resume System**

Never start from scratch again! The installation now tracks progress and can resume from where it left off after failures.

**Usage:**

```bash
# Installation automatically creates checkpoints
sudo CONFIRM_INSTALL=YES bash install/run-all.sh

# If it fails, just run the same command - it will resume
# View checkpoint status
cat /var/log/anthonyware-install/completed-scripts.log
```

**Features:**

- Tracks completed, failed, and skipped scripts
- Automatic resume on rerun
- Progress statistics
- No duplicate installations

---

### 2. **Hardware Detection & Optimization**

Automatically detects your hardware and optimizes the installation.

**What it detects:**

- GPU (NVIDIA/AMD/Intel/VM)
- CPU vendor and model
- RAM amount
- Firmware type (UEFI/BIOS)
- VM detection
- Network hardware

**Usage:**

```bash
# Hardware detection runs automatically
# View hardware report
cat ~/anthonyware-logs/hardware-report.txt

# Manual hardware detection
source install/lib/hardware.sh
hardware_report
hardware_recommendations
```

---

### 3. **Structured Logging System**

Beautiful, colorized logs with timestamps, log rotation, and error aggregation.

**Features:**

- Color-coded output (info=blue, success=green, error=red, warn=yellow)
- Per-script logs
- Centralized error log
- Automatic log rotation
- JSON export support

**Log locations:**

```
~/anthonyware-logs/
├── install-TIMESTAMP.log (main log)
├── errors.log (all errors)
├── 01-base-system.sh.log (per-script)
├── 02-gpu-drivers.sh.log
└── hardware-report.txt
```

---

### 4. **Profile System**

Choose a predefined installation profile to install only what you need.

**Available Profiles:**

| Profile | Size | Time | Description |
| --- | --- | --- | --- |
| `minimal` | 10GB | 15min | Base system + Hyprland only |
| `developer` | 20GB | 30min | Minimal + dev tools |
| `workstation` | 35GB | 60min | Full productivity setup |
| `gamer` | 25GB | 25min | Minimal + gaming |
| `homelab` | 25GB | 40min | Developer + homelab tools |
| `full` | 50GB | 75min | Everything |

**Usage:**

```bash
# Use a profile
sudo PROFILE=minimal CONFIRM_INSTALL=YES bash install/run-all.sh

# Interactive selection
sudo INTERACTIVE=1 bash install/run-all.sh
```

**Creating custom profiles:**

```bash
# Create profiles/custom.conf
cat > profiles/custom.conf <<EOF
# My Custom Profile
00-preflight-checks.sh
01-base-system.sh
02-gpu-drivers.sh
02-qt6-runtime.sh
03-hyprland.sh
04-daily-driver.sh
05-dev-tools.sh
33-user-configs.sh
35-validation.sh
EOF

# Use it
sudo PROFILE=custom CONFIRM_INSTALL=YES bash install/run-all.sh
```

---

### 5. **Config Backup System**

Automatically backs up existing configs before overwriting them.

**Features:**

- Timestamped backups
- Easy restoration
- Automatic cleanup of old backups

**Usage:**

```bash
# Backups are created automatically
# View backups
ls ~/.anthonyware-backups/

# Restore a backup
source install/lib/backup.sh
backup_list
backup_restore ~/.anthonyware-backups/2026-01-17-120000/

# Clean old backups (keeps last 5)
backup_clean
```

---

### 6. **Network Resilience**

Automatic retry logic for network failures and mirror optimization.

**Features:**

- Connectivity checks before installation
- Automatic retry with exponential backoff
- Mirror speed testing
- Failover to alternative mirrors

**Usage:**

```bash
# Network checking is automatic
# Manual network check
source install/lib/network.sh
check_network

# Wait for network
wait_for_network 30

# Retry a command
retry_command 3 5 pacman -Syu
```

---

### 7. **Interactive Component Selection**

Choose exactly which components to install with a friendly menu.

**Features:**

- Profile selection menu
- Individual component selection
- Confirmation dialog
- Progress display

**Usage:**

```bash
# Enable interactive mode
sudo INTERACTIVE=1 bash install/run-all.sh

# Or set profile and customize
sudo PROFILE=workstation INTERACTIVE=1 bash install/run-all.sh
```

---

### 8. **Config Validation**

Validates configuration files before deployment to prevent broken systems.

**Validates:**

- Hyprland configuration syntax
- JSON files
- JSONC files (JSON with comments)
- Kitty configuration

**Usage:**

```bash
# Validation runs automatically before config deployment
# Manual validation
source install/lib/validation.sh
validate_all_configs

# Validate specific file
validate_hyprland_conf configs/hypr/hyprland.conf
validate_json configs/waybar/config.json
```

---

### 9. **Post-Install Report**

Generates beautiful HTML and text reports of your installation.

**Features:**

- Installation statistics
- Hardware configuration
- Installed components
- Service status
- Next steps
- Troubleshooting links

**Report includes:**

- Scripts completed/failed/skipped
- Total duration
- Packages installed
- System services
- Error summary

**Locations:**

- HTML: `~/anthonyware-install-report.html`
- Text: `~/anthonyware-install-report.txt`

---

### 10. **Update Mechanism**

Safely update your Anthonyware installation.

**Features:**

- Git-based updates
- Automatic change detection
- Selective script re-running
- Config update prompts
- Automatic backups

**Usage:**

```bash
# Update Anthonyware
sudo bash scripts/update-anthonyware.sh

# It will:
# 1. Create backup
# 2. Pull latest changes
# 3. Detect changed scripts
# 4. Ask which to re-run
# 5. Apply updates
```

---

### 11. **Safe Uninstall**

Remove Anthonyware components cleanly.

**Features:**

- Selective removal
- Backup before uninstall
- Keeps user data
- Service cleanup

**Usage:**

```bash
# Uninstall Anthonyware
sudo bash scripts/uninstall-anthonyware.sh

# Interactive prompts for:
# - Remove packages?
# - Remove configs?
# - Remove repository?
# - Remove logs?
```

**What's kept:**

- User data in home directory
- Base system packages
- All backups

---

### 12. **Testing Framework**

Comprehensive test suite to validate the installation system.

**Tests include:**

- Script syntax validation
- Required files presence
- Shebang correctness
- Permission checks
- No hardcoded sudo
- Config file syntax
- SDDM package check
- Library files presence
- Profile files presence

**Usage:**

```bash
# Run all tests
bash tests/test-framework.sh

# Output shows:
# - ✓ Passed tests (green)
# - ✗ Failed tests (red)
# - ⊘ Skipped tests (yellow)
```

---

### 13. **Version Pinning**

Lock package versions for reproducible installations.

**Features:**

- Pin packages to specific versions
- Prevent accidental updates
- Reproducible builds

**Usage:**

```bash
# Lock current versions
sudo bash install/lib/version-pin.sh lock

# Install pinned versions
sudo bash install/lib/version-pin.sh install

# Show version status
sudo bash install/lib/version-pin.sh show

# Update lock file with current versions
sudo bash install/lib/version-pin.sh update

# Unlock versions
sudo bash install/lib/version-pin.sh unlock
```

**Lock file:** `versions.lock`

---

## 📚 Library System

All reusable functionality is now in modular libraries:

```
install/lib/
├── checkpoint.sh      - Checkpoint & resume
├── logging.sh         - Structured logging
├── hardware.sh        - Hardware detection
├── validation.sh      - Config validation
├── backup.sh          - Backup system
├── network.sh         - Network resilience
├── interactive.sh     - Interactive menus
├── report.sh          - Report generation
└── version-pin.sh     - Version pinning
```

**Using libraries in your scripts:**

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/lib/logging.sh"
source "$(dirname "$0")/lib/checkpoint.sh"

log_init
log_info "Starting my script"

checkpoint_complete "my-script.sh"
log_success "Done!"
```

---

## 🎨 UX Enhancements

### Progress Display

See exactly where you are in the installation:

```
[2/44] Installing: 02-gpu-drivers.sh
███████████████░░░░░░░░░░░░░░░░░░░░░ 35%
```

### Color-Coded Output

- 🔵 **Blue** - Information
- 🟢 **Green** - Success
- 🔴 **Red** - Errors
- 🟡 **Yellow** - Warnings

### Box Drawing

```
╔══════════════════════════════════════╗
║ Anthonyware OS Installation Report  ║
╚══════════════════════════════════════╝
```

---

## 🚀 Quick Start Examples

### Minimal Installation

```bash
sudo PROFILE=minimal CONFIRM_INSTALL=YES bash install/run-all.sh
```

### Developer Installation

```bash
sudo PROFILE=developer CONFIRM_INSTALL=YES bash install/run-all.sh
```

### Interactive Installation

```bash
sudo INTERACTIVE=1 bash install/run-all.sh
```

### Resume After Failure

```bash
# Just run the same command again
sudo CONFIRM_INSTALL=YES bash install/run-all.sh
```

### Test Before Installing

```bash
# Run all tests
bash tests/test-framework.sh

# Preview installation
DRY_RUN=1 bash install/run-all.sh

# Safe mode (skip risky components)
sudo SAFE_MODE=1 CONFIRM_INSTALL=YES bash install/run-all.sh
```

---

## 📖 Environment Variables Reference

| Variable | Description | Example |
| --- | --- | --- |
| `CONFIRM_INSTALL` | Skip confirmation prompt | `YES` |
| `PROFILE` | Use installation profile | `minimal`, `developer`, `full` |
| `INTERACTIVE` | Enable interactive mode | `1` |
| `DRY_RUN` | Preview without installing | `1` |
| `SAFE_MODE` | Skip risky components | `1` |
| `SKIP_STEPS` | Comma-separated scripts to skip | `17-steam.sh,11-vfio.sh` |
| `TARGET_USER` | Target username | `anthony` |
| `TARGET_HOME` | Target home directory | `/home/anthony` |
| `REPO_PATH` | Repository location | `/root/anthonyware-setup/anthonyware` |
| `LOG_DIR` | Log directory | `~/anthonyware-logs` |

---

## 🛠️ Troubleshooting

### Installation Failed

1. Check the error log: `cat ~/anthonyware-logs/errors.log`
2. Review the failed script log: `cat ~/anthonyware-logs/<script>.log`
3. Fix the issue
4. Resume: `sudo CONFIRM_INSTALL=YES bash install/run-all.sh`

### Config Validation Errors

```bash
# Check which configs are invalid
source install/lib/validation.sh
validate_all_configs
```

### Network Issues

```bash
# Test network connectivity
source install/lib/network.sh
check_network

# Try updating with mirrors
sudo pacman -Syy
```

### View Installation Status

```bash
# See completed scripts
cat /var/log/anthonyware-install/completed-scripts.log

# See checkpoint statistics
source install/lib/checkpoint.sh
checkpoint_stats
```

---

## 📦 What's Installed

See the generated report for complete details:

```bash
# View HTML report
xdg-open ~/anthonyware-install-report.html

# View text report
cat ~/anthonyware-install-report.txt
```

---

## 🔄 Update & Maintenance

### Update Anthonyware

```bash
sudo bash scripts/update-anthonyware.sh
```

### Backup Your Configs

```bash
source install/lib/backup.sh
backup_user_configs
```

### Clean Old Backups

```bash
source install/lib/backup.sh
backup_clean
```

### Lock Package Versions

```bash
sudo bash install/lib/version-pin.sh lock
```

---

## ❌ Uninstalling

```bash
sudo bash scripts/uninstall-anthonyware.sh
```

Interactive prompts will guide you through:

- Package removal
- Config cleanup
- Repository removal
- Log cleanup

Your data and backups are always preserved.

---

## 📝 Additional Documentation

- [INSTALL_INSTRUCTIONS.md](INSTALL_INSTRUCTIONS.md) - Detailed installation guide
- [INSTALLATION_FIXES_2026-01-17.md](INSTALLATION_FIXES_2026-01-17.md) - Bug fixes reference
- [docs/](docs/) - Workflow-specific guides

---

## 🆘 Support

1. **Check logs:** `~/anthonyware-logs/`
2. **Run tests:** `bash tests/test-framework.sh`
3. **View report:** `~/anthonyware-install-report.html`
4. **Check documentation:** All markdown files in repo root and `docs/`

---

**Version:** Anthonyware OS 1.0 - January 2026 Update  
**Status:** Production Ready ✅
