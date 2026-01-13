# Backup Strategy

## 1. Timeshift (Snapshots)
Automatic snapshots before updates.

## 2. Btrfs Snapshots
Stored in /.snapshots.

## 3. BorgBackup
Encrypted backups:
borg init --encryption=repokey /mnt/backup

## 4. Vorta
GUI for Borg.

## 5. Syncthing
Real-time sync between devices.

## 6. Restic
Cloud backups.
