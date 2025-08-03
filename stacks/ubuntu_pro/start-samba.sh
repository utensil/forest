#!/bin/bash
set -e

# AGENT-NOTE: Interactive Samba setup and start script

set -e

echo "=== Secure Samba Server Setup ==="

# Check if a Samba user already exists
EXISTING_USER=$(pdbedit -L | head -n1 | cut -d: -f1)
if [[ -n "$EXISTING_USER" ]]; then
  echo "Samba user '$EXISTING_USER' already exists. Please enter the password to reset it."
  while true; do
    smbpasswd "$EXISTING_USER" && break
    echo "Password setup failed. Try again."
  done
  if pgrep smbd > /dev/null; then
    echo "Samba server is already running (PID: $(pgrep smbd | tr '\n' ' '))."
  else
    echo "Starting Samba server as a daemon (non-root user: $EXISTING_USER)..."
    SMB_PORT="${SMB_PORT:-1445}"
    echo "Starting smbd as $EXISTING_USER on port $SMB_PORT..."
    exec su -s /bin/bash -c "smbd --foreground --debug-stdout --no-process-group" "$EXISTING_USER"
    # The above exec replaces the shell, so the following line will not run.
    # If you want to run in background, use:
    # su -s /bin/bash -c "smbd -p $SMB_PORT &" "$EXISTING_USER"
    # But for security, prefer exec (PID 1).
  fi
  exit 0
fi

# Always prompt for username interactively
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

# Allow Samba user to run veracrypt as root without password for FUSE mounting
SUDOERS_FILE="/etc/sudoers.d/veracrypt"
RULE="$SMB_USER ALL=(root) NOPASSWD: /usr/bin/veracrypt"
if ! grep -qF "$RULE" "$SUDOERS_FILE" 2>/dev/null; then
  echo "$RULE" >> "$SUDOERS_FILE"
  chmod 440 "$SUDOERS_FILE"
fi

# Set Samba password (always prompt interactively)
while true; do
  smbpasswd -a "$SMB_USER" && break
  echo "Password setup failed. Try again."
done



# Set permissions on shared directory
chown -R "$SMB_USER":smbgroup /mnt/shared
chmod 770 /mnt/shared

# AGENT-NOTE: Fix ownership of Samba state directories for non-root operation
for d in /var/lib/samba /var/run/samba /var/log/samba /run/samba; do
  if [ -d "$d" ]; then
    chown -R "$SMB_USER":smbgroup "$d"
  fi
done

echo "Samba user '$SMB_USER' created. Starting Samba server as a daemon (non-root user: $SMB_USER)..."
SMB_PORT="${SMB_PORT:-1445}"
echo "Starting smbd as $SMB_USER on port $SMB_PORT..."
#  --foreground --debug-stdout
exec su -s /bin/bash -c "smbd --no-process-group" "$SMB_USER"
# The above exec replaces the shell, so the following lines will not run.
# If you want to run in background, use:
# su -s /bin/bash -c "smbd -p $SMB_PORT &" "$SMB_USER"
# But for security, prefer exec (PID 1).

