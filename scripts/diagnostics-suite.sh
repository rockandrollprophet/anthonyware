#!/usr/bin/env bash
set -euo pipefail

# Anthonyware Diagnostics Suite
# Lightweight preflight/health checks with best-effort fallbacks.

log_file="/tmp/anthonyware-diagnostics-$(date +%Y%m%d-%H%M%S).log"

log() {
  printf "%s\n" "$*" | tee -a "$log_file"
}

run_check() {
  local title="$1"
  shift || true
  log "-- $title"
  {
    "$@"
  } 2>&1 | tee -a "$log_file" || log "   [WARN] $title reported issues"
  log
}

log "=== Anthonyware Diagnostics Suite ==="
log "Log: $log_file"
log

# 1) Environment summary
run_check "Environment summary" bash -lc "echo Shell: $SHELL; uname -a; lsb_release -d 2>/dev/null || cat /etc/os-release"

# 2) Network reachability
run_check "Network: ping archlinux.org" bash -lc "ping -c1 -W2 archlinux.org >/dev/null && echo OK || (curl -Is https://archlinux.org >/dev/null && echo OK_via_https || echo FAIL)"

# 3) Disk & space
run_check "Disk layout" lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
run_check "Root free space" df -h /

# 4) Firmware mode
run_check "Firmware mode" bash -lc "if [ -d /sys/firmware/efi ]; then echo UEFI; else echo Legacy; fi"

# 5) Secure Boot state (best effort)
run_check "Secure Boot" bash -lc "if [ -f /sys/firmware/efi/efivars/SecureBoot-* ]; then hexdump -v -e '1/1 "%02x"' /sys/firmware/efi/efivars/SecureBoot-* | grep -q '01000000' && echo Enabled || echo Disabled; else echo Unknown; fi"

# 6) CPU virtualization flags
run_check "CPU virtualization" bash -lc "if grep -Eq 'vmx|svm' /proc/cpuinfo; then echo VT/AMD-V present; else echo NO_VIRT_FLAGS; fi"

# 7) Memory snapshot
run_check "Memory" free -h

# 8) Package manager lock (Arch)
run_check "pacman lock" bash -lc "if [ -e /var/lib/pacman/db.lck ]; then echo LOCKED; else echo clear; fi"

# 9) Mirror sanity (Arch)
run_check "pacman mirrors" bash -lc "grep -E '^[[:space:]]*Server' /etc/pacman.d/mirrorlist | head -3"

# 10) Disk health (best effort)
run_check "NVMe health" bash -lc "if command -v nvme >/dev/null; then nvme list 2>/dev/null || true; else echo 'nvme not installed'; fi"
run_check "S.M.A.R.T. health" bash -lc "if command -v smartctl >/dev/null; then smartctl --scan | head -3 | while read -r dev _; do [ -n "$dev" ] && smartctl -H "$dev"; done; else echo 'smartmontools not installed'; fi"

# 11) Repo integrity (if present)
run_check "Repo integrity" bash -lc "if [ -x scripts/usb-integrity-check.sh ]; then scripts/usb-integrity-check.sh; else echo 'skipped (scripts/usb-integrity-check.sh missing)'; fi"

# 12) Existing preflight (if present)
run_check "Pre-install check" bash -lc "if [ -x pre-install-check.sh ]; then pre-install-check.sh; else echo 'skipped (pre-install-check.sh missing)'; fi"

# Simple summary
pass=0; warn=0; fail=0
# Heuristics: search for keywords in the log
if grep -qi "OK\|UEFI\|clear\|present" "$log_file"; then pass=$((pass+1)); fi
if grep -qi "WARN\|Unknown" "$log_file"; then warn=$((warn+1)); fi
if grep -qi "FAIL\|LOCKED\|NO_VIRT_FLAGS" "$log_file"; then fail=$((fail+1)); fi

overall="PASS"
if [[ $fail -gt 0 ]]; then overall="FAIL"; elif [[ $warn -gt 0 ]]; then overall="WARN"; fi

log "Summary: overall=$overall pass=$pass warn=$warn fail=$fail"
log "Diagnostics complete. See log: $log_file"
