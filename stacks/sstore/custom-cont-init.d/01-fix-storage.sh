#!/bin/sh
# Fix /storage ownership on every container start.
# Needed when the storage backend (e.g. exFAT disk) resets ownership on remount.
chown "${PUID}:${PGID}" /storage
