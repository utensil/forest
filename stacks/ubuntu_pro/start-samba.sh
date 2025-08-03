#!/bin/bash
set -e

# AGENT-NOTE: Interactive Samba setup and start script

set -e

echo "=== Secure Samba Server Setup ==="

# Check if a Samba user already exists
EXISTING_USER=$(pdbedit -L | head -n1 | cut -d: -f1)
if [[ -n "$EXISTING_USER" ]]; then
  echo "Samba user '$EXISTING_USER' already exists. Skipping setup."
  if pgrep smbd > /dev/null; then
    echo "Samba server is already running (PID: $(pgrep smbd | tr '\n' ' '))."
  else
    echo "Starting Samba server as a daemon..."
    smbd
    echo "Samba server started in background."
  fi
  exit 0
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
  # Create user with UID 1000, GID 1000, home dir, shell, and add to fuse group if present
  if getent group fuse > /dev/null; then
    useradd -m -u 1000 -g 1000 -G smbgroup,fuse -s /bin/bash "$SMB_USER"
  else
    useradd -m -u 1000 -g 1000 -G smbgroup -s /bin/bash "$SMB_USER"
  fi
  # Set smbgroup GID to 1000 if not already
  groupmod -g 1000 smbgroup || true
fi

# Set Samba password policies BEFORE setting password
pdbedit -P "min password length" -C 10
pdbedit -P "password history" -C 5
pdbedit -P "bad lockout attempt" -C 10

# Prompt for password and set Samba password interactively
while true; do
  smbpasswd -a "$SMB_USER" && break
  echo "Password setup failed. Try again."
done



# Set permissions on shared directory
chown -R "$SMB_USER":smbgroup /mnt/shared
chmod 770 /mnt/shared

echo "Samba user '$SMB_USER' created. Starting Samba server as a daemon..."
smbd
if pgrep smbd > /dev/null; then
  echo -e "\033[1;32mSamba server is UP! (PID: $(pgrep smbd | tr '\n' ' '))\033[0m"
  echo "To stop Samba, run: /stop-samba.sh"
else
  echo "Failed to start Samba server. Check logs."
fi
