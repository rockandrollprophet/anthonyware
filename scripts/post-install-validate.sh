#!/usr/bin/env bash
set -euo pipefail

echo "=== Anthonyware Post-Install Validation ==="

# 1. Core services
echo
echo "--- Systemd service status (critical) ---"
systemctl is-active NetworkManager || echo "NetworkManager NOT active"
systemctl is-active firewalld || echo "firewalld NOT active"
systemctl is-active libvirtd || echo "libvirtd NOT active"
systemctl is-active cups || echo "cups NOT active"
systemctl is-active tlp || echo "tlp NOT active"
systemctl is-active thermald || echo "thermald NOT active"

# 2. GPU
echo
echo "--- GPU detection ---"
lspci | grep -E "VGA|3D" || echo "No GPU found?"

# 3. Wayland / Hyprland presence
echo
echo "--- Hyprland binaries ---"
command -v hyprland || echo "Hyprland not found in PATH"
command -v waybar || echo "Waybar not found in PATH"
command -v kitty || echo "Kitty not found in PATH"

# 4. Dev tools
echo
echo "--- Dev tools ---"
command -v git || echo "git missing"
command -v gcc || echo "gcc missing"
command -v python || echo "python missing"
command -v node || echo "node missing"
command -v go || echo "go missing"
command -v rustup || echo "rustup missing"
command -v code || echo "VS Code missing"

# 5. AI/ML
echo
echo "--- AI/ML stack quick check ---"
python - << 'EOF' || echo "Python AI/ML sanity check failed"
import torch
print("PyTorch CUDA available:", torch.cuda.is_available())
EOF

# 6. CAD/CNC/3D printing
echo
echo "--- CAD/CNC tools ---"
command -v blender || echo "blender missing"
command -v kicad || echo "kicad missing"
command -v freecad || echo "freecad missing"
command -v prusa-slicer || echo "prusa-slicer missing"

# 7. Backup tools
echo
echo "--- Backup tools ---"
command -v timeshift || echo "timeshift missing"
command -v borg || echo "borg missing"
command -v vorta || echo "vorta missing"
command -v syncthing || echo "syncthing missing"

# 8. Security
echo
echo "--- Security tools ---"
command -v firejail || echo "firejail missing"
command -v keepassxc || echo "keepassxc missing"
command -v veracrypt || echo "veracrypt missing"

echo
echo "=== Post-install validation complete ==="