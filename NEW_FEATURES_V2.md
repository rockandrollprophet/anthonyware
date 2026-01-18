# Anthonyware OS V2.0 - New Features

## Overview

Anthonyware OS V2.0 represents a major evolution from V1, adding enterprise-grade reliability, security hardening, reproducibility, observability, and extensibility features while maintaining the streamlined Arch Linux + Hyprland foundation.

## Core V2 Features

### 🛡️ Reliability & Recovery

- **Snapshot + Rollback**: BTRFS snapshot support with automatic rollback on script failure
- **Overlay Apply Mode**: Test changes in temporary overlay before committing
- **Health Gating**: Battery, disk space, and thermal checks before installation
- **Self-Test Harness**: Automated validation of install pipeline integrity
- **Rescue Bundle Generator**: Export logs, metrics, and diagnostics for offline troubleshooting
- **Offline Install Mode**: Cache packages and repo for air-gapped installations

### 🔐 Security & Hardening

- **Secrets Management**: Secure handling of credentials (sops integration optional)
- **Sandboxed Installers**: Optional firejail/bwrap isolation for install scripts
- **Supply Chain Verification**: Checksum and signature validation for packages
- **Posture Checks**: sysctl and service hardening validation (enforce/warn/skip modes)
- **Policy Engine**: Declarative MUST/SHOULD/FORBID rules for security compliance

### 📦 Reproducibility & Compliance

- **Version Pinning**: Full lockfile support for pacman/AUR/pip/npm packages
- **SBOM Generation**: Software Bill of Materials with SHA256 provenance
- **Deterministic Templates**: Jinja2-style templating for configuration files
- **Reproducible Builds**: Capture exact package versions and build environments

### 📊 Observability & UX

- **JSONL Metrics & Timeline**: Structured logging with per-script duration and status
- **HTML Timeline Reports**: Visual installation timeline with error correlation
- **TUI Wizard**: Interactive profile and component selection (whiptail/dialog/fzf)
- **Guided Remediation**: Context-aware troubleshooting hints for failures
- **Progress Indicators**: Real-time installation progress with percentage complete

### 🎯 Profiles & Targeting

- **Minimal**: Base + Hyprland (10GB, ~15 min)
- **Developer**: Minimal + dev tools (20GB, ~30 min)
- **Workstation**: Full-featured productivity (35GB, ~60 min)
- **Gamer**: Gaming-optimized (25GB, ~25 min)
- **Homelab**: Server admin tools (25GB, ~40 min)
- **Laptop**: Power-tuned mobile (25GB, ~30 min)
- **Server**: Headless hardened (15GB, ~20 min)
- **Cloud**: Lean VM/container footprint (12GB, ~15 min)
- **Color-Managed**: Calibrated display workflow (30GB, ~40 min)
- **Full**: Everything (50GB, ~75 min)
- **Custom**: Component checklist selection

### ⚡ Performance & Footprint

- **Package Cache Prefetch**: Background database sync during early stages
- **Parallel Execution**: Safe parallelization of independent install stages
- **Lean Mode**: Automatic removal of docs, locales, package cache (~3-5GB savings)
- **Optimized Tuning Scripts**: Per-profile sysctl and service optimizations

### 🔧 Extensibility & Policy

- **Plugin System**: YAML-defined hooks (pre-install, post-install, per-script)
- **anthonyctl CLI**: Unified management tool (status, resume, rollback, validate, doctor)
- **Config Packs**: Shareable preset bundles for specific workflows
- **Policy Validation**: Runtime enforcement of installation requirements

### 🧪 Safety & Validation

- **Idempotence Testing**: Automated detection of non-idempotent scripts
- **Dry-Run Diff**: Preview system changes before execution
- **Enforcement Gates**: Block installation if critical validations fail

### 🛠️ Developer Tooling & CI

- **Shellcheck Integration**: Automated linting of all bash scripts
- **shfmt Formatting**: Consistent code style across codebase
- **GitHub Actions CI**: Automated testing on push/PR
- **Test Framework**: Comprehensive validation suite

## Usage Examples

### Basic Installation with Profile

```bash
sudo PROFILE=developer CONFIRM_INSTALL=YES bash install/run-all.sh
```

### Interactive Mode with TUI

```bash
sudo INTERACTIVE=1 CONFIRM_INSTALL=YES bash install/run-all.sh
```

### Lean Cloud Install

```bash
sudo PROFILE=cloud LEAN_MODE=1 CONFIRM_INSTALL=YES bash install/run-all.sh
```

### Hardened Server with Snapshots

```bash
sudo PROFILE=server ENABLE_SNAPSHOTS=1 POSTURE_MODE=enforce CONFIRM_INSTALL=YES bash install/run-all.sh
```

### Resume from Checkpoint

```bash
sudo CONFIRM_INSTALL=YES bash install/run-all.sh  # Auto-resumes
# Or use anthonyctl
./scripts/anthonyctl.sh resume
```

### Generate Rescue Bundle

```bash
./scripts/rescue-bundle.sh
# Creates /tmp/anthonyware-rescue-TIMESTAMP.tar.gz
```

### Validate with Policies

```bash
sudo POLICY_MODE=enforce bash install/run-all.sh
# Enforces policies in policies/*.policy
```

### Export Metrics and Timeline

```bash
# Metrics are auto-generated during install
cat ~/anthonyware-logs/metrics/metrics.jsonl
cat ~/anthonyware-logs/metrics/timeline.jsonl
# HTML report includes visual timeline
```

## Environment Variables

### Core Toggles

- `PROFILE`: Installation profile (minimal|developer|workstation|gamer|homelab|laptop|server|cloud|color-managed|full|custom)
- `INTERACTIVE`: Enable TUI wizard (0|1)
- `DRY_RUN`: Preview without executing (0|1)
- `SAFE_MODE`: Skip risky components (0|1)
- `LEAN_MODE`: Minimize footprint (0|1)

### Reliability

- `ENABLE_SNAPSHOTS`: BTRFS snapshot per script (0|1)
- `ROLLBACK_ON_FAIL`: Auto-rollback on failure (0|1)
- `SELF_TEST`: Run self-test harness before install (0|1)
- `HEALTH_IGNORE_BATTERY`: Bypass battery checks (0|1)

### Security

- `POSTURE_MODE`: Hardening validation (enforce|warn|skip)
- `SANDBOX_MODE`: Sandboxed execution (optional|enforce|off)
- `SANDBOX_TOOL`: Sandbox engine (auto|firejail|bwrap|none)
- `POLICY_MODE`: Policy enforcement (enforce|warn|skip)

### Observability

- `METRICS_DIR`: Metrics output directory
- `TUI_MODE`: TUI engine (auto|whiptail|dialog|fzf|none)

### Performance

- `ENABLE_CACHE`: Package metadata prefetch (0|1)
- `ENABLE_PARALLEL`: Parallel execution (0|1, opt-in)
- `PARALLEL_JOBS`: Max parallel workers (default: 4)

### Extensibility

- `ENABLE_PLUGINS`: Enable plugin system (0|1)
- `PLUGIN_DIR`: Plugin directory path

### Offline/Recovery

- `OFFLINE_MODE`: Offline installation (0|1)
- `OFFLINE_CACHE`: Offline package cache path

## Configuration Files

### Profiles

Located in `profiles/*.conf`:

- Line-based script lists
- `@include` directive for composition
- Comments with `#`

### Policies

Located in `policies/*.policy`:

```
MUST package_installed firefox "Firefox must be installed"
SHOULD service_enabled sshd "SSH recommended for remote access"
FORBID package_installed telnet "Telnet forbidden for security"
```

### Plugins

Located in `plugins/*/`:

```
plugin-name/
  plugin.yaml      # Manifest (name, version, hooks, dependencies)
  plugin.sh        # Main script with exported functions
  hooks/           # Hook scripts (pre-install.sh, post-install.sh, etc.)
```

## anthonyctl Commands

```bash
anthonyctl status       # Show installation status and health
anthonyctl resume       # Resume from checkpoint
anthonyctl rollback     # Rollback to snapshot
anthonyctl update       # Update all components
anthonyctl validate     # Run validation checks
anthonyctl report       # Generate HTML report
anthonyctl metrics      # Show metrics summary
anthonyctl logs         # View logs
anthonyctl snapshot     # Create snapshot
anthonyctl cleanup      # Clean caches
anthonyctl doctor       # Run diagnostics
```

## Migration from V1

V2 is backward compatible with V1 installations. Existing systems can:

1. Update to V2: `git pull && sudo bash install/99-update-everything.sh`
2. Run validation: `./scripts/anthonyctl.sh validate`
3. Generate SBOM: `./scripts/generate-sbom.sh`
4. Enable new features by setting environment variables

## Performance Improvements

V2 includes several performance optimizations:

- **Cache prefetch**: ~2-5 min faster pacman operations
- **Lean mode**: 3-5GB disk space savings
- **Parallel execution**: Up to 20-30% faster on safe script groups (opt-in)
- **Profile targeting**: Install only what you need

## Security Enhancements

- Sandboxed script execution isolates installation processes
- Supply chain verification prevents tampered packages
- Posture checks enforce hardening best practices
- Policy engine blocks forbidden configurations
- Secrets management prevents credential leakage

## Troubleshooting

### Installation Failed

1. Check logs: `tail -f ~/anthonyware-logs/*.log`
2. View remediation: `cat ~/anthonyware-logs/guided-remediation.txt`
3. Run diagnostics: `./scripts/anthonyctl.sh doctor`
4. Generate rescue bundle: `./scripts/rescue-bundle.sh`

### Health Checks Blocking

```bash
# Bypass battery check
sudo HEALTH_IGNORE_BATTERY=1 CONFIRM_INSTALL=YES bash install/run-all.sh

# Skip all health checks
sudo HEALTH_SKIP_ALL=1 CONFIRM_INSTALL=YES bash install/run-all.sh
```

### Sandbox Issues

```bash
# Disable sandbox
sudo SANDBOX_MODE=off CONFIRM_INSTALL=YES bash install/run-all.sh
```

### Policy Violations

```bash
# Warn only (don't enforce)
sudo POLICY_MODE=warn CONFIRM_INSTALL=YES bash install/run-all.sh

# Skip policy checks
sudo POLICY_MODE=skip CONFIRM_INSTALL=YES bash install/run-all.sh
```

## Future Roadmap

Potential V2.x enhancements:

- Golden image builder for VM templates
- Network install server with PXE boot
- A/B partition management
- Container-native install mode
- Automated update scheduling

## Credits

Anthonyware OS V2.0 builds on the solid V1 foundation with contributions from the community and inspiration from enterprise Linux deployment tools.
