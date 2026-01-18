#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# validation.sh - Configuration file validation before deployment

# Validate Hyprland config syntax
validate_hyprland_conf() {
  local config_file="$1"
  
  if [[ ! -f "$config_file" ]]; then
    echo "ERROR: Config file not found: $config_file"
    return 1
  fi
  
  # Check for common syntax errors
  local errors=0
  
  # Check for unmatched braces
  local open_braces=$(grep -o '{' "$config_file" | wc -l)
  local close_braces=$(grep -o '}' "$config_file" | wc -l)
  if [[ $open_braces -ne $close_braces ]]; then
    echo "ERROR: Unmatched braces in $config_file (open:$open_braces close:$close_braces)"
    ((errors++))
  fi
  
  # Check for required sections
  local required_sections=("general" "decoration" "animations")
  for section in "${required_sections[@]}"; do
    if ! grep -q "^[[:space:]]*$section[[:space:]]*{" "$config_file"; then
      echo "WARN: Missing section '$section' in $config_file"
    fi
  done
  
  # Try to parse with Hyprland if available
  if command -v Hyprland >/dev/null 2>&1; then
    if ! Hyprland --config "$config_file" --help &>/dev/null; then
      echo "ERROR: Hyprland failed to parse config"
      ((errors++))
    fi
  fi
  
  return $errors
}

# Validate JSON files (waybar, swaync, etc.)
validate_json() {
  local json_file="$1"
  
  if [[ ! -f "$json_file" ]]; then
    echo "ERROR: JSON file not found: $json_file"
    return 1
  fi
  
  if command -v jq >/dev/null 2>&1; then
    if ! jq empty "$json_file" 2>/dev/null; then
      echo "ERROR: Invalid JSON in $json_file"
      jq empty "$json_file" 2>&1 | head -5
      return 1
    fi
  else
    # Fallback: basic JSON validation
    if ! python3 -c "import json; json.load(open('$json_file'))" 2>/dev/null; then
      echo "ERROR: Invalid JSON in $json_file"
      return 1
    fi
  fi
  
  echo "✓ Valid JSON: $json_file"
  return 0
}

# Validate JSONC (JSON with comments - waybar)
validate_jsonc() {
  local jsonc_file="$1"
  
  if [[ ! -f "$jsonc_file" ]]; then
    echo "ERROR: JSONC file not found: $jsonc_file"
    return 1
  fi
  
  # Strip comments and validate
  local temp_json=$(mktemp)
  sed 's|//.*||g' "$jsonc_file" > "$temp_json"
  
  local result=0
  if ! validate_json "$temp_json"; then
    echo "ERROR: Invalid JSONC in $jsonc_file"
    result=1
  else
    echo "✓ Valid JSONC: $jsonc_file"
  fi
  
  rm -f "$temp_json"
  return $result
}

# Validate Kitty config
validate_kitty_conf() {
  local config_file="$1"
  
  if [[ ! -f "$config_file" ]]; then
    echo "ERROR: Config file not found: $config_file"
    return 1
  fi
  
  if command -v kitty >/dev/null 2>&1; then
    if ! kitty --config "$config_file" --debug-config &>/dev/null; then
      echo "ERROR: Kitty failed to parse config"
      return 1
    fi
  fi
  
  echo "✓ Valid Kitty config: $config_file"
  return 0
}

# Validate all configs before deployment
validate_all_configs() {
  local config_dir="$1"
  local errors=0
  
  echo "Validating configuration files..."
  echo
  
  # Hyprland configs
  if [[ -f "$config_dir/hypr/hyprland.conf" ]]; then
    validate_hyprland_conf "$config_dir/hypr/hyprland.conf" || ((errors++))
  fi
  
  # JSON configs
  for json in "$config_dir"/swaync/*.json "$config_dir"/eww/*.json; do
    [[ -f "$json" ]] && { validate_json "$json" || ((errors++)); }
  done
  
  # JSONC configs
  for jsonc in "$config_dir"/waybar/*.jsonc "$config_dir"/fastfetch/*.jsonc; do
    [[ -f "$jsonc" ]] && { validate_jsonc "$jsonc" || ((errors++)); }
  done
  
  # Kitty config
  if [[ -f "$config_dir/kitty/kitty.conf" ]]; then
    validate_kitty_conf "$config_dir/kitty/kitty.conf" || ((errors++))
  fi
  
  echo
  if [[ $errors -eq 0 ]]; then
    echo "✓ All configuration files validated successfully"
    return 0
  else
    echo "✗ $errors configuration error(s) found"
    return 1
  fi
}

# Export functions
export -f validate_hyprland_conf
export -f validate_json
export -f validate_jsonc
export -f validate_kitty_conf
export -f validate_all_configs
