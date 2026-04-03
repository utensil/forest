#!/bin/sh
# Restore claude config from backup if missing (not covered by named volume)
if [ ! -f /root/.claude.json ]; then
  backup=$(ls /root/.claude/backups/.claude.json.backup.* 2>/dev/null | sort | tail -1)
  if [ -n "$backup" ]; then
    cp "$backup" /root/.claude.json
  fi
fi

# Start lody daemon in background so this device is connected to lody.ai
nohup lody start > /var/log/lody.log 2>&1 &

exec "$@"
