#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# ///
"""
prep_homelab.py
===============

Idempotently manages /etc/hosts entries for all stacks/*, mapping [stack].homelab.local to a given IP (default 127.0.0.1).

- Scans stacks/ for subdirectories (stack names)
- Writes a block to /etc/hosts with lines like:
    127.0.0.1 dockge.homelab.local
- Uses clear marker comments for safe reentry
- Accepts IP as first argument (default 127.0.0.1)
- Uses sudo if needed
- Idempotent: safe to run repeatedly

Usage:
    uv run stacks/caddy/prep_homelab.py [IP]
"""
import sys
import os
from pathlib import Path
import subprocess

MARKER_BEGIN = "# AGENT-HOMELAB-BEGIN"
MARKER_END = "# AGENT-HOMELAB-END"
STACKS_DIR = Path(__file__).parent.parent
HOSTS_PATH = "/etc/hosts"

ip = sys.argv[1] if len(sys.argv) > 1 else "127.0.0.1"

# Find stack subdirectories
stack_names = [d.name for d in STACKS_DIR.iterdir() if d.is_dir() and not d.name.startswith('.') and d.name != "caddy"]

# Compose new block
block_lines = [MARKER_BEGIN]
for name in sorted(stack_names):
    block_lines.append(f"{ip} {name}.homelab.local")
block_lines.append(MARKER_END)
block = "\n".join(block_lines) + "\n"

# Read current /etc/hosts
with open(HOSTS_PATH, "r") as f:
    lines = f.readlines()

# Remove any previous block
in_block = False
new_lines = []
for line in lines:
    if line.strip() == MARKER_BEGIN:
        in_block = True
        continue
    if line.strip() == MARKER_END:
        in_block = False
        continue
    if not in_block:
        new_lines.append(line)

# Add new block at end
new_lines.append(block)
new_content = "".join(new_lines)

# Write back, using sudo if needed
try:
    with open(HOSTS_PATH, "w") as f:
        f.write(new_content)
except PermissionError:
    # Use sudo tee
    print("Permission denied, retrying with sudo...")
    p = subprocess.Popen(["sudo", "tee", HOSTS_PATH], stdin=subprocess.PIPE)
    p.communicate(new_content.encode())
    if p.returncode != 0:
        print("Failed to write /etc/hosts with sudo.", file=sys.stderr)
        sys.exit(1)
