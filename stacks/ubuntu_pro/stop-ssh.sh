#!/bin/bash
# AGENT-NOTE: Stops the SSH server and removes the specified user from sudoers
set -e

read -rp "Enter username to remove from sudoers and stop SSH: " SSH_USER
while [[ -z "$SSH_USER" ]]; do
    read -rp "Username cannot be empty. Enter username: " SSH_USER
done

# Remove user from sudoers
if grep -q "^$SSH_USER ALL=(ALL) NOPASSWD:ALL" /etc/sudoers; then
    sed -i "/^$SSH_USER ALL=(ALL) NOPASSWD:ALL/d" /etc/sudoers
    echo "Removed $SSH_USER from sudoers."
else
    echo "$SSH_USER not found in sudoers."
fi

# Stop SSH server gracefully
if pgrep -x sshd >/dev/null; then
    pkill -TERM sshd
    echo "sshd stopped."
else
    echo "sshd is not running."
fi
