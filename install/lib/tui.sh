#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# tui.sh - Simple TUI wrappers (whiptail/dialog/fzf fallback)

TUI_MODE=${TUI_MODE:-auto}  # auto|whiptail|dialog|fzf|none

_tui_log_info(){ if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }

_tui_pick_tool() {
  local tool="$TUI_MODE"
  if [[ "$tool" == "auto" ]]; then
    if command -v whiptail >/dev/null 2>&1; then tool="whiptail";
    elif command -v dialog >/dev/null 2>&1; then tool="dialog";
    elif command -v fzf >/dev/null 2>&1; then tool="fzf";
    else tool="none"; fi
  fi
  echo "$tool"
}

# Present a list selection; opts passed as TAG "Description" pairs for dialog/whiptail; fzf shows both
tui_menu() {
  local title="$1"; shift
  local opts=("$@")
  local tool=$(_tui_pick_tool)
  case "$tool" in
    whiptail)
      whiptail --title "$title" --menu "$title" 20 70 12 "${opts[@]}" 3>&1 1>&2 2>&3
      ;;
    dialog)
      dialog --title "$title" --menu "$title" 20 70 12 "${opts[@]}" 3>&1 1>&2 2>&3
      ;;
    fzf)
      printf '%s\n' "${opts[@]}" | paste - - | sed 's/\t/ /' | fzf --with-nth=1.. --prompt "$title> " | awk '{print $1}'
      ;;
    *)
      echo "${opts[0]}"
      ;;
  esac
}

# Yes/No dialog, returns 0 for yes
tui_yesno() {
  local title="$1" prompt="$2"
  local tool=$(_tui_pick_tool)
  case "$tool" in
    whiptail)
      whiptail --title "$title" --yesno "$prompt" 10 70
      return $?
      ;;
    dialog)
      dialog --title "$title" --yesno "$prompt" 10 70
      return $?
      ;;
    fzf)
      echo -e "Yes\nNo" | fzf --prompt "$title> " | grep -qi yes
      return $?
      ;;
    *)
      read -rp "$prompt [Y/n] " ans
      [[ ! "$ans" =~ ^[Nn]$ ]]
      return $?
      ;;
  esac
}

# Checklist dialog, returns CSV of selected tags
tui_checklist() {
  local title="$1"; shift
  local opts=("$@")
  local tool=$(_tui_pick_tool)
  case "$tool" in
    whiptail)
      whiptail --title "$title" --checklist "$title" 20 80 12 "${opts[@]}" 3>&1 1>&2 2>&3 | tr -d '"' | tr ' ' ','
      ;;
    dialog)
      dialog --title "$title" --checklist "$title" 20 80 12 "${opts[@]}" 3>&1 1>&2 2>&3 | tr ' ' ','
      ;;
    fzf)
      # opts expected as TAG "Desc" STATE triplets; display tag desc pairs for fzf multi-select
      local lines=()
      local idx=0
      while [[ $idx -lt ${#opts[@]} ]]; do
        local tag="${opts[$idx]}"; local desc="${opts[$((idx+1))]}"; local state="${opts[$((idx+2))]}"
        lines+=("${tag} ${desc} [${state}]")
        idx=$((idx+3))
      done
      printf '%s\n' "${lines[@]}" | fzf -m --prompt "$title> " | awk '{print $1}' | paste -sd, -
      ;;
    *)
      # Fallback: return first option tag (enabled ones)
      local selected=()
      local i=0
      while [[ $i -lt ${#opts[@]} ]]; do
        local tag="${opts[$i]}"; local desc="${opts[$((i+1))]}"; local state="${opts[$((i+2))]}"
        if [[ "$state" == "on" ]]; then selected+=("$tag"); fi
        i=$((i+3))
      done
      (IFS=','; echo "${selected[*]}")
      ;;
  esac
}

export -f tui_menu
export -f tui_yesno
export -f tui_checklist
