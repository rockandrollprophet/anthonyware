#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  00-create-user.sh
#  MANUAL USER ACCOUNT CREATION SCRIPT
#  
#  Run this as root after base system installation.
#  This script MUST be run before the main installation pipeline.
# ============================================================

if [[ "${EUID}" -ne 0 ]]; then
  echo "ERROR: This script must be run as root."
  echo "       Login as root and run: bash 00-create-user.sh"
  exit 1
fi

echo "╔══════════════════════════════════════════════════════╗"
echo "║ Anthonyware User Account Setup                       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo

# Pre-create groups that will be used by the pipeline
# (packages will add them if they don't exist, but we create them now
# so the user can be added to them immediately)
for group in docker libvirt wireshark; do
  if ! getent group "$group" >/dev/null 2>&1; then
    echo "Creating group: $group"
    groupadd "$group" || true
  fi
done
echo
echo "This script will create your user account and configure sudo access."
echo

# Get username
while true; do
  read -rp "Enter username: " USERNAME
  if [[ -n "$USERNAME" && "$USERNAME" != "root" ]]; then
    break
  else
    echo "ERROR: Username cannot be empty or 'root'. Try again."
  fi
done

# Check if user already exists
if id "$USERNAME" &>/dev/null; then
  echo
  echo "User $USERNAME already exists."
  read -rp "Continue with existing user? [y/N] " ans
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
else
  # Create user
  echo
  echo "Creating user: $USERNAME"
  if ! useradd -m -G wheel,docker,libvirt,wireshark -s /bin/bash "$USERNAME"; then
    echo "ERROR: Failed to create user $USERNAME"
    exit 1
  fi
  
  # Ensure home directory exists and has correct permissions
  local home_dir="/home/$USERNAME"
  if [[ ! -d "$home_dir" ]]; then
    echo "WARNING: Home directory not created, creating manually..."
    mkdir -p "$home_dir"
    chown "$USERNAME:$USERNAME" "$home_dir"
    chmod 700 "$home_dir"
  fi
  
  echo "✓ User created"
fi

# Set user password
echo
echo "Setting password for $USERNAME"
if ! passwd "$USERNAME"; then
  echo "ERROR: Failed to set user password"
  exit 1
fi
echo "✓ User password set"

# Set root password
echo
echo "Setting root password"
if ! passwd root; then
  echo "ERROR: Failed to set root password"
  exit 1
fi
echo "✓ Root password set"

# Configure sudo
echo
echo "Configuring sudo access..."
SUDOERS_FILE="/etc/sudoers.d/10-wheel"
if [[ ! -f "$SUDOERS_FILE" ]]; then
  echo "%wheel ALL=(ALL:ALL) ALL" > "$SUDOERS_FILE"
  chmod 440 "$SUDOERS_FILE"
  echo "✓ Sudo configured for wheel group"
else
  echo "✓ Sudo already configured"
fi

# Verify user is in wheel group
if ! groups "$USERNAME" | grep -q wheel; then
  echo "Adding $USERNAME to wheel group..."
  usermod -aG wheel "$USERNAME"
fi

# Add to additional groups if they exist
for group in docker libvirt wireshark; do
  if getent group "$group" >/dev/null 2>&1; then
    if ! groups "$USERNAME" | grep -q "$group"; then
      usermod -aG "$group" "$USERNAME" 2>/dev/null || true
    fi
  fi
done

echo
echo "╔══════════════════════════════════════════════════════╗"
echo "║ User Account Setup Complete                          ║"
echo "╚══════════════════════════════════════════════════════╝"
echo
echo "User:   $USERNAME"
echo "Groups: $(groups $USERNAME | cut -d: -f2)"
echo "Sudo:   Enabled"
echo
echo "Next steps:"
echo "  1. Logout from root: exit"
echo "  2. Login as $USERNAME"
echo "  3. Verify sudo works: sudo whoami"
echo "  4. Run installation pipeline:"
echo "     cd /root/anthonyware-setup/anthonyware/install"
echo "     sudo CONFIRM_INSTALL=YES TARGET_USER=\"$USERNAME\" \\"
echo "          TARGET_HOME=\"/home/$USERNAME\" \\"
echo "          REPO_PATH=\"/root/anthonyware-setup/anthonyware\" \\"
echo "          bash run-all.sh"
echo

read -rp "Logout and switch to $USERNAME now? [Y/n] " ans
if [[ ! "$ans" =~ ^[Nn]$ ]]; then
  echo
  echo "Logging out..."
  sleep 2
  exit 0
fi
