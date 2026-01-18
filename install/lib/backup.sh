#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# backup.sh - Backup existing configurations before overwriting

BACKUP_DIR="${BACKUP_DIR:-${HOME}/.anthonyware-backups}"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')

# Initialize backup system
backup_init() {
  mkdir -p "$BACKUP_DIR"
  echo "Backup directory: $BACKUP_DIR"
}

# Backup a single file
backup_file() {
  local source="$1"
  local name="${2:-$(basename "$source")}"
  
  if [[ ! -f "$source" ]]; then
    return 0  # Nothing to backup
  fi
  
  local backup_path="${BACKUP_DIR}/${name}.${TIMESTAMP}.bak"
  cp -p "$source" "$backup_path"
  echo "✓ Backed up: $source → $backup_path"
}

# Backup a directory
backup_dir() {
  local source="$1"
  local name="${2:-$(basename "$source")}"
  
  if [[ ! -d "$source" ]]; then
    return 0  # Nothing to backup
  fi
  
  local backup_path="${BACKUP_DIR}/${name}.${TIMESTAMP}.tar.gz"
  tar -czf "$backup_path" -C "$(dirname "$source")" "$(basename "$source")"
  echo "✓ Backed up: $source → $backup_path"
}

# Backup user configs before deployment
backup_user_configs() {
  local target_home="$1"
  
  echo "Backing up existing user configurations..."
  
  # Config directories to backup
  local configs=(
    "${target_home}/.config/hypr"
    "${target_home}/.config/waybar"
    "${target_home}/.config/kitty"
    "${target_home}/.config/mako"
    "${target_home}/.config/wofi"
    "${target_home}/.config/eww"
    "${target_home}/.config/swaync"
  )
  
  for config in "${configs[@]}"; do
    if [[ -d "$config" ]]; then
      backup_dir "$config" "$(basename "$(dirname "$config")")-$(basename "$config")"
    fi
  done
  
  # Important files
  [[ -f "${target_home}/.zshrc" ]] && backup_file "${target_home}/.zshrc"
  [[ -f "${target_home}/.bashrc" ]] && backup_file "${target_home}/.bashrc"
  
  echo "✓ Backup complete"
}

# List available backups
backup_list() {
  echo "Available backups in $BACKUP_DIR:"
  ls -lh "$BACKUP_DIR" 2>/dev/null || echo "No backups found"
}

# Restore a backup
backup_restore() {
  local backup_file="$1"
  local target="$2"
  
  if [[ ! -f "$backup_file" ]]; then
    echo "ERROR: Backup file not found: $backup_file"
    return 1
  fi
  
  if [[ "$backup_file" == *.tar.gz ]]; then
    tar -xzf "$backup_file" -C "$(dirname "$target")"
    echo "✓ Restored: $backup_file → $target"
  else
    cp -p "$backup_file" "$target"
    echo "✓ Restored: $backup_file → $target"
  fi
}

# Clean old backups (keep last 5)
backup_clean() {
  local keep_count=5
  
  cd "$BACKUP_DIR" || return
  
  # Group by base name and keep only recent ones
  for base in $(ls | sed 's/\.[0-9]\{8\}-[0-9]\{6\}\.bak$//' | sort -u); do
    ls -t ${base}.*.bak 2>/dev/null | tail -n +$((keep_count + 1)) | xargs -r rm -f
    ls -t ${base}.*.tar.gz 2>/dev/null | tail -n +$((keep_count + 1)) | xargs -r rm -f
  done
  
  echo "✓ Cleaned old backups (kept last $keep_count of each)"
}

# Export functions
export -f backup_init
export -f backup_file
export -f backup_dir
export -f backup_user_configs
export -f backup_list
export -f backup_restore
export -f backup_clean
