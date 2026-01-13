# Update Strategy

## 1. Update Everything
./install/99-update-everything.sh

## 2. Before Major Updates
- Create Timeshift snapshot
- Sync dotfiles
- Backup with Borg

## 3. After Updates
- Reboot
- Verify GPU
- Verify VM passthrough
