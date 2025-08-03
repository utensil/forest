#!/bin/bash
set -e

# AGENT-NOTE: Interactive Samba test script

read -p "Enter Samba username: " SMB_USER
read -s -p "Enter Samba password: " SMB_PASS

echo

SMB_PORT=${SMB_PORT:-1445}
SHARE_NAME=${SHARE_NAME:-shared}

# Test listing the share
smbclient //localhost/$SHARE_NAME -p $SMB_PORT -U "$SMB_USER%$SMB_PASS" -c 'ls'

if [ $? -eq 0 ]; then
  echo "Samba test succeeded: able to list //$SHARE_NAME as $SMB_USER."
else
  echo "Samba test failed. Check credentials and server status."
  exit 1
fi
