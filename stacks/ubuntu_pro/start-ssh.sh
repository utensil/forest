#!/bin/bash
# AGENT-NOTE: Starts the SSH server in the container, disables root login, and sets up passwordless sudo for an interactively created user
set -e

SSH_PORT="${SSH_PORT:-22}"

# Ensure SSH host keys exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# Ensure privilege separation directory exists
mkdir -p /run/sshd

# Disable root login and allow password authentication
sed -i 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Prompt for username
read -rp "Enter username to create for SSH and sudo: " SSH_USER
while [[ -z "$SSH_USER" ]]; do
    read -rp "Username cannot be empty. Enter username: " SSH_USER
done

# Create user if not exists
if ! id "$SSH_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$SSH_USER"
fi

# Prompt to set password for the user
passwd "$SSH_USER"

# Add user to sudoers with NOPASSWD
if ! grep -q "^$SSH_USER" /etc/sudoers; then
    echo "$SSH_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi


# Ask if SSH should run in foreground or as daemon
read -rp "Run SSH server in foreground or as daemon? [F/d]: " SSH_MODE
case "${SSH_MODE,,}" in
    d)
        echo "Starting sshd as daemon..."
        /usr/sbin/sshd -p "$SSH_PORT"
        ;;
    *)
        echo "Starting sshd in foreground..."
        exec /usr/sbin/sshd -D -p "$SSH_PORT"
        ;;
esac
