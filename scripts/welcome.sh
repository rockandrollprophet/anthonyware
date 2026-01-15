#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  welcome.sh
#  Post-install welcome and quick reference
# ============================================================

clear
cat << 'EOF'
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║  🚀 Welcome to Anthonyware OS 1.0                       ║
║                                                          ║
║  A fully provisioned, validated, and instrumented       ║
║  engineering workstation with:                          ║
║                                                          ║
║  • Hyprland wayland desktop                             ║
║  • Full development stack                               ║
║  • AI/ML ecosystem (PyTorch, TensorFlow, Jupyter)       ║
║  • CAD/CAM/3D printing support                          ║
║  • Electrical engineering & FPGA tools                  ║
║  • Security hardening & virtualization                  ║
║  • Automated backups & diagnostics                      ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝

📋 QUICK COMMANDS

  health-dashboard          Quick system health summary
  validate-configs          Verify all user configs
  backup-system             Create system snapshot
  backup-home               Backup home directory
  update-everything         Full system + repo update
  rollback-to-factory       Restore baseline snapshot

📂 IMPORTANT DIRECTORIES

  ~/anthonyware/            Repository root
  ~/anthonyware-logs/       Installation logs
  ~/.config/hypr/           Hyprland config
  ~/.local/bin/             User scripts & binaries

📚 DOCUMENTATION

  docs/install-guide.md     Full installation guide
  docs/first-boot-checklist.md
  QUICK_START.md            Package reference

🎯 NEXT STEPS

  1. Review system health:    health-dashboard
  2. Customize Hyprland:      $EDITOR ~/.config/hypr/hyprland.conf
  3. Set up backups:          backup-system
  4. Configure SSH:           ssh-keygen -t ed25519
  5. Test development tools:  python -c "import torch"

⚠️  First Boot Notes

  • Password must be changed on first login
  • NVIDIA users: drivers loaded automatically
  • AMD users: firmware may need loading
  • Wayland sessions are default; Xwayland available
  • Docker daemon starts on demand

🔒 SECURITY

  • Firewall: enabled (firewalld)
  • AppArmor: enabled
  • SSH: edit /etc/ssh/sshd_config
  • Backups: Timeshift snapshots in /.snapshots/

🎮 GAMING / VMs

  • Steam:        Pre-installed with Proton
  • QEMU/KVM:     virt-manager GUI available
  • Windows VM:   See docs/vm/windows-install.md

❓ NEED HELP?

  • Repository: https://github.com/YOUR_NAME/anthonyware
  • Logs:       ~/anthonyware-logs/
  • Issues:     Check QUICK_START.md

═══════════════════════════════════════════════════════════

Press Enter to continue...
EOF

read -r

echo
echo "System info:"
uname -a
echo
echo "Disk usage:"
df -h / | tail -1
echo
echo "RAM:"
free -h | grep Mem
