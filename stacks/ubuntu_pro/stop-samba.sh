#!/bin/bash
set -e

# AGENT-NOTE: Gracefully stop all Samba (smbd) processes

if pgrep smbd > /dev/null; then
  echo "Stopping Samba server (PID: $(pgrep smbd | tr '\n' ' '))..."
  pkill smbd
  sleep 1
  if pgrep smbd > /dev/null; then
    echo "Some smbd processes are still running. Killing forcefully."
    pkill -9 smbd
  fi
  echo "Samba server stopped."
else
  echo "Samba server is not running."
fi
