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

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

# --- Robust UID/GID 1000 logic for single-user scenario ---
# Always create group if missing
if ! getent group smbgroup > /dev/null; then
  if ! groupadd smbgroup; then
    echo "Failed to create group smbgroup"
    exit 1
  fi
fi

# Check if GID 1000 is used by a group other than smbgroup
GID_1000_GROUP=$(getent group 1000 | cut -d: -f1)
if [[ -n "$GID_1000_GROUP" && "$GID_1000_GROUP" != "smbgroup" ]]; then
  echo "WARNING: GID 1000 is already used by group '$GID_1000_GROUP'."
  read -p "Change '$GID_1000_GROUP' to a new GID? [y/N]: " CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    NEW_GID=$(shuf -i 2000-2999 -n 1)
    groupmod -g "$NEW_GID" "$GID_1000_GROUP"
    echo "Changed group '$GID_1000_GROUP' to GID $NEW_GID."
  else
    echo "Aborting. GID 1000 must be reserved for smbgroup."
    exit 1
  fi
fi
# Set smbgroup GID to 1000 if not already
if [[ $(getent group smbgroup | cut -d: -f3) != "1000" ]]; then
  groupmod -g 1000 smbgroup
fi

# Check if UID 1000 is used by a user other than $SMB_USER
UID_1000_USER=$(getent passwd 1000 | cut -d: -f1)
if [[ -n "$UID_1000_USER" && "$UID_1000_USER" != "$SMB_USER" ]]; then
  echo "WARNING: UID 1000 is already used by user '$UID_1000_USER'."
  read -p "Change '$UID_1000_USER' to a new UID? [y/N]: " CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    NEW_UID=$(shuf -i 2000-2999 -n 1)
    usermod -u "$NEW_UID" "$UID_1000_USER"
    echo "Changed user '$UID_1000_USER' to UID $NEW_UID."
  else
    echo "Aborting. UID 1000 must be reserved for $SMB_USER."
    exit 1
  fi
fi

# Create user if not exist, else check UID/GID
if ! id "$SMB_USER" > /dev/null 2>&1; then
  if getent group fuse > /dev/null; then
    useradd -m -u 1000 -g 1000 -G smbgroup,fuse -s /bin/bash "$SMB_USER"
  else
    useradd -m -u 1000 -g 1000 -G smbgroup -s /bin/bash "$SMB_USER"
  fi
else
  # User exists, check UID/GID
  CUR_UID=$(id -u "$SMB_USER")
  CUR_GID=$(id -g "$SMB_USER")
  if [[ "$CUR_UID" != "1000" || "$CUR_GID" != "1000" ]]; then
    echo "User '$SMB_USER' exists but does not have UID/GID 1000 (UID=$CUR_UID, GID=$CUR_GID)."
    read -p "Change '$SMB_USER' to UID/GID 1000? [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      usermod -u 1000 "$SMB_USER"
      groupmod -g 1000 "$SMB_USER"
      usermod -g 1000 "$SMB_USER"
      echo "Changed '$SMB_USER' to UID/GID 1000."
    else
      echo "Aborting. UID/GID 1000 must be reserved for $SMB_USER."
      exit 1
    fi
  fi
fi
# Always add user to smbgroup (even if user already existed)
usermod -aG smbgroup "$SMB_USER"

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

