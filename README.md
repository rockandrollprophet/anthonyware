# Anthonyware OS (Arch + Hyprland)

A fully modular, reproducible engineering workstation built on Arch Linux and Hyprland.

This repo contains:

- Install scripts
- Config files
- VM passthrough setup
- Engineering tools
- AI/ML stack
- CAD/CAM/CNC/3D printing stack
- Electrical engineering stack
- Security hardening
- Backup strategy

## Full Install

Use these commands for operators. The installer writes logs to `anthonyware-logs` and auto-runs troubleshooting on failures.

- Preview (no changes):

    ```bash
    DRY_RUN=1 bash install/run-all.sh
    ```

- Full run (executes all steps, including GPU drivers):

    ```bash
    CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

- Optional: create a snapshot before changes (best-effort rollback point):

    ```bash
    bash scripts/system-snapshot.sh
    ```

### Notes

- If a step fails, the orchestrator runs `scripts/troubleshoot-all.sh` and copies logs into `anthonyware-logs`.
- To selectively skip steps, set `SKIP_STEPS="scriptA.sh,scriptB.sh"` when running.
- To preview with a skip list, combine with `DRY_RUN=1`.

## Unattended Install

Prepare an answers file (or run the interactive setup) so inputs are gathered once and reused.

- Interactive setup (creates user, grants sudo, sets passwords):

    ```bash
    bash scripts/collect-input.sh
    CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

- Answers file approach (fully unattended, no prompts):

    ```bash
    cat > answers.env <<EOF
    TARGET_USER=alice
    HOSTNAME=lab-m17
    REPO_PATH=/home/alice/anthonyware
    EOF
    ANSWERS_FILE=answers.env CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

- Auto-create user with input collector:

    ```bash
    ALLOW_CREATE_USER=1 bash scripts/collect-input.sh
    CONFIRM_INSTALL=YES bash install/run-all.sh
    ```

- Notes:

  - Passwords are not stored in the answers file. Set interactively via the collector or manually with `passwd`.
  - The collector checks if the user exists; if not, it prompts to create and configure (or auto-create with `ALLOW_CREATE_USER=1`).
  - Sudo permissions and root password are configured during setup.
  - Logs live in `anthonyware-logs`; check `run-all.log` and per-step logs if needed.
