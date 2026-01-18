# Anthonyware OS V2.0 (Arch + Hyprland)

A fully modular, reproducible **graduate-level engineering and scientific computing workstation** built on Arch Linux and Hyprland with enterprise-grade reliability, security, and observability.

**V2.0 Highlights**: Snapshot rollback, sandboxed installs, policy enforcement, SBOM generation, interactive TUI, 10 installation profiles, lean mode, plugin system, and comprehensive observability.

**Pre-installed**: 260+ engineering packages including CAD (Fusion 360, Blender, FreeCAD), FPGA tools (Yosys, nextpnr), AI/ML frameworks (PyTorch, TensorFlow), EE tools (KiCAD, ngspice), and more. Zero post-install setup required.

This repo contains:

- Install scripts (38 modular, ordered by dependency)
- Config files (Hyprland, Kitty, Waybar, etc.)
- VM passthrough setup (VFIO for Windows CAD tools)
- Engineering tools (260+ packages pre-installed)
- AI/ML stack (PyTorch, TensorFlow, JupyterLab, transformers)
- CAD/CAM/CNC/3D printing stack
- Electrical engineering stack (KiCAD, ngspice, logic analyzers)
- FPGA toolchain (Yosys, nextpnr, Verilator, GHDL)
- Security hardening
- Backup strategy
- Validation & diagnostics

**Documentation**:

- [V2 New Features](NEW_FEATURES_V2.md) — Complete guide to V2 enhancements
- [What's pre-installed](docs/whats-preinstalled.md) — Complete engineering environment overview
- [Engineering setup guide](docs/engineering-setup.md) — Tool-by-tool breakdown and workflows
- [Installation guide](docs/install-guide.md) — Step-by-step install + disk partitioning (800-900GB)
- [Workflows](docs/) — CAD, AI/ML, FPGA, VFIO, security, etc.

## Quick Install

Use these commands for operators. The installer writes logs to `anthonyware-logs` and auto-runs troubleshooting on failures.

- **Interactive mode with TUI wizard** (recommended):

    ```bash
    sudo INTERACTIVE=1 CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

- **Profile-based install** (developer, workstation, gamer, laptop, server, cloud, etc.):

    ```bash
    sudo PROFILE=developer CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

- **Minimal install** (Base + Hyprland, ~10GB, 15 min):

    ```bash
    sudo PROFILE=minimal CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

- **Lean cloud install** (headless, minimal footprint):

    ```bash
    sudo PROFILE=cloud LEAN_MODE=1 CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

- **Preview (no changes)**:

    ```bash
    DRY_RUN=1 bash install/run-all.sh
    ```

- **Full install** with snapshots and hardening:

    ```bash
    sudo ENABLE_SNAPSHOTS=1 POSTURE_MODE=enforce CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

## Available Profiles

- `minimal` - Base + Hyprland (10GB, ~15 min)
- `developer` - Minimal + dev tools (20GB, ~30 min)
- `workstation` - Full productivity suite (35GB, ~60 min)
- `gamer` - Gaming optimized (25GB, ~25 min)
- `homelab` - Server/admin tools (25GB, ~40 min)
- `laptop` - Power-tuned mobile (25GB, ~30 min)
- `server` - Headless hardened (15GB, ~20 min)
- `cloud` - Lean VM footprint (12GB, ~15 min)
- `color-managed` - Display calibration (30GB, ~40 min)
- `full` - Everything (50GB, ~75 min)
- `custom` - Interactive component selection

## Management with anthonyctl

```bash
# Check status
./scripts/anthonyctl.sh status

# Resume from checkpoint
./scripts/anthonyctl.sh resume

# Rollback to snapshot
./scripts/anthonyctl.sh rollback

# Update all components
./scripts/anthonyctl.sh update

# Run diagnostics
./scripts/anthonyctl.sh doctor

# Generate report
./scripts/anthonyctl.sh report

# View metrics
./scripts/anthonyctl.sh metrics

# Create rescue bundle
./scripts/rescue-bundle.sh
```

### Notes

- **Checkpoint & Resume**: Installation automatically resumes from last successful step if interrupted
- **Snapshot Rollback**: Set `ENABLE_SNAPSHOTS=1` for automatic rollback on failure (BTRFS required)
- **Health Gating**: Battery, disk, and thermal checks prevent installation on unhealthy systems
  - Bypass with `HEALTH_IGNORE_BATTERY=1` or `HEALTH_SKIP_ALL=1`
- **Sandbox Mode**: Optional isolation with firejail/bwrap (`SANDBOX_MODE=optional|enforce|off`)
- **Policy Validation**: Enforce security/compliance rules (`POLICY_MODE=enforce|warn|skip`)
- **Metrics & Timeline**: JSONL logs and HTML reports with per-script duration tracking
- **Lean Mode**: Save 3-5GB by removing docs, locales, and caches (`LEAN_MODE=1`)
- **Parallel Execution**: Speed up safe script groups (`ENABLE_PARALLEL=1`, opt-in)
- **Plugin System**: Extend with custom hooks in `plugins/` directory
- **Troubleshooting**: Failures auto-run diagnostics; check `anthonyware-logs/guided-remediation.txt`
- **Offline Mode**: Cache packages for air-gapped installs with `scripts/offline-prepare.sh`

## Unattended Install

Prepare an answers file (or run the interactive setup) so inputs are gathered once and reused.

- **Interactive TUI setup** (recommended):

    ```bash
    sudo INTERACTIVE=1 CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

- **Profile-based unattended**:

    ```bash
    sudo PROFILE=developer CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

- **Answers file approach** (fully unattended, no prompts):

    ```bash
    cat > answers.env <<EOF
    TARGET_USER=alice
    HOSTNAME=lab-m17
    REPO_PATH=/home/alice/anthonyware
    PROFILE=developer
    ENABLE_SNAPSHOTS=1
    LEAN_MODE=0
    EOF
    ANSWERS_FILE=answers.env CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

- **Auto-create user with input collector**:

    ```bash
    ALLOW_CREATE_USER=1 bash scripts/collect-input.sh
    CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

## Key Environment Variables

**Core**:

- `PROFILE` - Installation profile (minimal|developer|workstation|gamer|homelab|laptop|server|cloud|color-managed|full|custom)
- `INTERACTIVE` - Enable TUI wizard (0|1)
- `DRY_RUN` - Preview without executing (0|1)
- `SAFE_MODE` - Skip risky components (0|1)
- `LEAN_MODE` - Minimize footprint (0|1)

**Reliability**:

- `ENABLE_SNAPSHOTS` - BTRFS snapshot per script (0|1)
- `ROLLBACK_ON_FAIL` - Auto-rollback on failure (0|1)
- `SELF_TEST` - Run self-test before install (0|1)
- `HEALTH_IGNORE_BATTERY` - Bypass battery checks (0|1)

**Security**:

- `POSTURE_MODE` - Hardening validation (enforce|warn|skip)
- `SANDBOX_MODE` - Sandboxed execution (optional|enforce|off)
- `POLICY_MODE` - Policy enforcement (enforce|warn|skip)

**Performance**:

- `ENABLE_CACHE` - Package prefetch (0|1, default: 1)
- `ENABLE_PARALLEL` - Parallel execution (0|1, opt-in)
- `PARALLEL_JOBS` - Max workers (default: 4)

**Observability**:

- `METRICS_DIR` - Metrics output path
- `TUI_MODE` - TUI engine (auto|whiptail|dialog|fzf|none)

See [NEW_FEATURES_V2.md](NEW_FEATURES_V2.md) for complete documentation.

- Notes:

  - Passwords are not stored in the answers file. Set interactively via the collector or manually with `passwd`.
  - The collector checks if the user exists; if not, it prompts to create and configure (or auto-create with `ALLOW_CREATE_USER=1`).
  - Sudo permissions and root password are configured during setup.
  - Logs live in `anthonyware-logs`; check `run-all.log` and per-step logs if needed.
  - Metrics, timeline, and SBOM are automatically generated in the logs directory.
