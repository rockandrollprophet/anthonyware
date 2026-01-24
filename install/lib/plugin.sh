#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# plugin.sh - Plugin system for extensibility

PLUGIN_DIR="${PLUGIN_DIR:-${REPO_PATH:-/root/anthonyware-setup/anthonyware}/plugins}"
ENABLE_PLUGINS="${ENABLE_PLUGINS:-1}"

_plugin_log_info(){ if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_plugin_log_warn(){ if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }

# Plugin manifest format (plugin.yaml):
# name: my-plugin
# version: 1.0.0
# description: Custom installation component
# hooks:
#   - pre-install
#   - post-install
# scripts:
#   - install.sh
#   - configure.sh

# Load plugin
plugin_load() {
  local plugin_name="$1"
  local plugin_path="$PLUGIN_DIR/$plugin_name"
  
  if [[ ! -d "$plugin_path" ]]; then
    _plugin_log_warn "Plugin not found: $plugin_name"
    return 1
  fi
  
  # Source plugin scripts
  if [[ -f "$plugin_path/plugin.sh" ]]; then
    # shellcheck disable=SC1090
    source "$plugin_path/plugin.sh"
    _plugin_log_info "Loaded plugin: $plugin_name"
    return 0
  else
    _plugin_log_warn "Plugin missing plugin.sh: $plugin_name"
    return 1
  fi
}

# Run plugin hook
plugin_run_hook() {
  local hook_name="$1"
  shift
  local hook_args=("$@")
  
  [[ "$ENABLE_PLUGINS" != "1" ]] && return 0
  
  if [[ ! -d "$PLUGIN_DIR" ]]; then
    return 0
  fi
  
  _plugin_log_info "Running plugin hook: $hook_name"
  
  # Find all plugins with this hook
  while IFS= read -r plugin_dir; do
    local plugin_name=$(basename "$plugin_dir")
    local hook_script="$plugin_dir/hooks/${hook_name}.sh"
    
    if [[ -f "$hook_script" && -x "$hook_script" ]]; then
      _plugin_log_info "  Executing $plugin_name/$hook_name"
      bash "$hook_script" "${hook_args[@]}" || _plugin_log_warn "  Hook failed: $plugin_name/$hook_name"
    fi
  done < <(find "$PLUGIN_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
}

# List available plugins
plugin_list() {
  if [[ ! -d "$PLUGIN_DIR" ]]; then
    echo "No plugins directory found"
    return 0
  fi
  
  echo "Available plugins:"
  while IFS= read -r plugin_dir; do
    local plugin_name=$(basename "$plugin_dir")
    local manifest="$plugin_dir/plugin.yaml"
    
    if [[ -f "$manifest" ]]; then
      local desc=$(grep "^description:" "$manifest" | cut -d: -f2- | xargs)
      echo "  - $plugin_name: $desc"
    else
      echo "  - $plugin_name (no manifest)"
    fi
  done < <(find "$PLUGIN_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
}

# Validate plugin structure
plugin_validate() {
  local plugin_name="$1"
  local plugin_path="$PLUGIN_DIR/$plugin_name"
  
  if [[ ! -d "$plugin_path" ]]; then
    echo "Plugin not found: $plugin_name"
    return 1
  fi
  
  local errors=0
  
  # Check for required files
  if [[ ! -f "$plugin_path/plugin.sh" ]]; then
    echo "  Missing: plugin.sh"
    ((errors++))
  fi
  
  if [[ ! -f "$plugin_path/plugin.yaml" ]]; then
    echo "  Missing: plugin.yaml"
    ((errors++))
  fi
  
  # Check hooks directory
  if [[ -d "$plugin_path/hooks" ]]; then
    while IFS= read -r hook_file; do
      if [[ ! -x "$hook_file" ]]; then
        echo "  Hook not executable: $(basename "$hook_file")"
        ((errors++))
      fi
    done < <(find "$plugin_path/hooks" -name "*.sh" -type f 2>/dev/null)
  fi
  
  if [[ $errors -eq 0 ]]; then
    echo "Plugin validation passed: $plugin_name"
    return 0
  else
    echo "Plugin validation failed: $plugin_name ($errors errors)"
    return 1
  fi
}

export -f plugin_load
export -f plugin_run_hook
export -f plugin_list
export -f plugin_validate
