#!/bin/bash
set -e

# AGENT-NOTE: Interactive Samba setup and start script

set -e

echo "=== Secure Samba Server Setup ==="

# Check if a Samba user already exists
EXISTING_USER=$(pdbedit -L | head -n1 | cut -d: -f1)
if [[ -n "$EXISTING_USER" ]]; then
  echo "Samba user '$EXISTING_USER' already exists. Skipping setup."
  echo "Starting Samba..."
  exec smbd -F --no-process-group
fi

# Prompt for username
while true; do
  read -p "Enter Samba username: " SMB_USER
  if [[ -z "$SMB_USER" ]]; then
    echo "Username cannot be empty."
  else
    break
  fi
done

# Create group and user if not exist
if ! getent group smbgroup > /dev/null; then
  groupadd smbgroup
fi
if ! id "$SMB_USER" > /dev/null 2>&1; then
  useradd -M -s /usr/sbin/nologin -G smbgroup "$SMB_USER"
fi

# Prompt for password (hidden input) and set Samba password
while true; do
  smbpasswd -a "$SMB_USER" && break
  echo "Password setup failed. Try again."
done

# Set permissions on shared directory
chown -R "$SMB_USER":smbgroup /mnt/shared
chmod 770 /mnt/shared

echo "Samba user '$SMB_USER' created. Starting Samba..."
exec smbd -F --no-process-group
