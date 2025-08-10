#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["pexpect>=4.8.0"]
# ///
"""
Ephemeral Samba Test User Script
================================

This script is for ephemeral, in-memory testing of the Samba setup in the container.
It is NOT included in the Docker image. Run it from your mounted project directory.

Usage (from host, with project mounted in container):

    docker exec <container> /root/.local/share/mise/shims/uv run /mnt/yourproject/stacks/ubuntu_pro/test-samba-init.py

- Generates a random username (4 lowercase letters + 5 digits, e.g. abcd12345) and a secure random password.
- Credentials are used only in memory for the test and are never printed or persisted.
- After testing, start a new instance and initialize interactively for real use.

"""

import secrets
import string
import pexpect
import sys

# AGENT-NOTE: Limitation
# If a Samba user already exists, /start-samba.sh calls smbpasswd interactively.
# This cannot be controlled by the outer pexpect script, so the test will hang or fail in the "existing user" flow.
# Workarounds: always remove the user before running, or refactor /start-samba.sh for non-interactive password setting.
def debug(msg):
    print(f"[DEBUG] {msg}", file=sys.stderr)

# Generate a simple random username: 4 lowercase letters + 5 digits
username = ''.join(secrets.choice(string.ascii_lowercase) for _ in range(4)) + ''.join(secrets.choice(string.digits) for _ in range(5))
# Generate a secure random password (16 chars, letters+digits+punctuation)
alphabet = string.ascii_letters + string.digits + string.punctuation
password = ''.join(secrets.choice(alphabet) for _ in range(16))

child = pexpect.spawn('/start-samba.sh')
debug('Spawned /start-samba.sh')
try:
    index = child.expect([
        'Enter Samba username:',
        f"Samba user '{username}' already exists. Please enter the password to reset it.",
        'New SMB password:'
    ], timeout=60)
    debug(f'Got prompt index {index}: {child.before}')
    # Loop through prompts until we reach the run mode prompt
    while True:
        try:
            idx = child.expect([
                'Enter Samba username:',
                'New SMB password:',
                'Retype new SMB password:',
                'Run Samba server in foreground or as daemon\? \[F/d\]:',
                pexpect.EOF
            ], timeout=60)
            debug(f'Loop expect idx {idx}: {child.before}')
            if idx == 0:
                debug('Sending username')
                child.sendline(username)
            elif idx == 1:
                debug('Sending password')
                child.sendline(password)
            elif idx == 2:
                debug('Retyping password')
                child.sendline(password)
            elif idx == 3:
                debug('Got foreground/daemon prompt, sending d')
                child.sendline('d')
                child.expect(pexpect.EOF, timeout=60)
                debug('Samba server started in daemon mode')
                break
            elif idx == 4:
                debug('Got EOF before run mode prompt')
                break
        except pexpect.TIMEOUT:
            debug(f'TIMEOUT in loop. Buffer: {child.before}')
            debug(f'Full output so far: {child.before + child.after if hasattr(child, "after") else child.before}')
            sys.exit(5)
        except pexpect.EOF:
            debug(f'EOF in loop. Buffer: {child.before}')
            debug(f'Full output so far: {child.before + child.after if hasattr(child, "after") else child.before}')
            sys.exit(6)

except pexpect.TIMEOUT:
    debug(f'TIMEOUT. Buffer: {child.before}')
    sys.exit(1)
except pexpect.EOF:
    debug(f'EOF. Buffer: {child.before}')
    sys.exit(1)

import sys

# Test smbclient access to the share
smbclient_cmd = [
    'smbclient',
    f'//localhost/shared',
    f'-U{username}%{password}',
    '-c', 'ls'
]
child2 = pexpect.spawn(' '.join(smbclient_cmd))
debug('Spawned smbclient for connectivity test')
try:
    index = child2.expect([
        'NT_STATUS_LOGON_FAILURE',  # Authentication failed
        'NT_STATUS_ACCESS_DENIED',  # Access denied
        'Domain=.*OS=.*Server=.*',  # Successful connection banner
        'smb: \\> ',              # smbclient prompt (success)
        pexpect.EOF
    ], timeout=30)
    debug(f'smbclient expect index {index}: {child2.before}')
    if index in [0, 1]:
        debug('smbclient authentication or access failed')
        sys.exit(2)
    # Success if we see the banner or prompt
    debug('smbclient connected successfully')
except pexpect.TIMEOUT:
    debug(f'smbclient TIMEOUT. Buffer: {child2.before}')
    sys.exit(3)
except pexpect.EOF:
    debug(f'smbclient EOF. Buffer: {child2.before}')
    sys.exit(4)
# Do not print or persist anything

