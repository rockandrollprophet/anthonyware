#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# network.sh - Network resilience and retry logic

MAX_RETRIES="${MAX_RETRIES:-3}"
RETRY_DELAY="${RETRY_DELAY:-5}"

# Check network connectivity
check_network() {
  local test_hosts=("archlinux.org" "google.com" "1.1.1.1")
  
  for host in "${test_hosts[@]}"; do
    if ping -c 1 -W 2 "$host" &>/dev/null; then
      return 0
    fi
  done
  
  return 1
}

# Wait for network to be available
wait_for_network() {
  local max_wait="${1:-30}"
  local waited=0
  
  echo "Waiting for network connectivity..."
  
  while [[ $waited -lt $max_wait ]]; do
    if check_network; then
      echo "✓ Network is available"
      return 0
    fi
    
    sleep 2
    ((waited += 2))
    echo -n "."
  done
  
  echo
  echo "✗ Network not available after ${max_wait}s"
  return 1
}

# Retry a command with exponential backoff
retry_command() {
  local max_attempts="$1"
  shift
  local command=("$@")
  local attempt=1
  local delay="$RETRY_DELAY"
  
  while [[ $attempt -le $max_attempts ]]; do
    echo "Attempt $attempt/$max_attempts: ${command[*]}"
    
    if "${command[@]}"; then
      return 0
    fi
    
    if [[ $attempt -lt $max_attempts ]]; then
      echo "Failed. Retrying in ${delay}s..."
      sleep "$delay"
      delay=$((delay * 2))  # Exponential backoff
    fi
    
    ((attempt++))
  done
  
  echo "✗ Command failed after $max_attempts attempts"
  return 1
}

# Pacman with retry
pacman_retry() {
  retry_command "$MAX_RETRIES" pacman "$@"
}

# Git clone with retry
git_clone_retry() {
  local url="$1"
  local dest="$2"
  
  retry_command "$MAX_RETRIES" git clone "$url" "$dest"
}

# Curl with retry
curl_retry() {
  retry_command "$MAX_RETRIES" curl --retry 3 --retry-delay 2 "$@"
}

# Wget with retry
wget_retry() {
  retry_command "$MAX_RETRIES" wget --tries=3 --wait=2 "$@"
}

# Yay with retry
yay_retry() {
  retry_command "$MAX_RETRIES" yay "$@"
}

# Download file with multiple methods
download_file() {
  local url="$1"
  local output="$2"
  
  # Try curl first
  if command -v curl >/dev/null 2>&1; then
    if curl_retry -L -o "$output" "$url"; then
      return 0
    fi
  fi
  
  # Fallback to wget
  if command -v wget >/dev/null 2>&1; then
    if wget_retry -O "$output" "$url"; then
      return 0
    fi
  fi
  
  echo "✗ Failed to download: $url"
  return 1
}

# Check if mirror is responsive
check_mirror() {
  local mirror="$1"
  curl -s -m 5 "$mirror" >/dev/null 2>&1
}

# Find fastest mirror from list
find_fastest_mirror() {
  local mirrors=("$@")
  local fastest=""
  local best_time=999999
  
  for mirror in "${mirrors[@]}"; do
    local start=$(date +%s%N)
    if check_mirror "$mirror"; then
      local end=$(date +%s%N)
      local elapsed=$(( (end - start) / 1000000 ))  # Convert to ms
      
      if [[ $elapsed -lt $best_time ]]; then
        best_time=$elapsed
        fastest="$mirror"
      fi
    fi
  done
  
  echo "$fastest"
}

# Export functions
export -f check_network
export -f wait_for_network
export -f retry_command
export -f pacman_retry
export -f git_clone_retry
export -f curl_retry
export -f wget_retry
export -f yay_retry
export -f download_file
export -f check_mirror
export -f find_fastest_mirror
