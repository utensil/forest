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

# Generate a simple random username: 4 lowercase letters + 5 digits
username = ''.join(secrets.choice(string.ascii_lowercase) for _ in range(4)) + ''.join(secrets.choice(string.digits) for _ in range(5))
# Generate a secure random password (16 chars, letters+digits+punctuation)
alphabet = string.ascii_letters + string.digits + string.punctuation
password = ''.join(secrets.choice(alphabet) for _ in range(16))

child = pexpect.spawn('/start-samba.sh')
# Handle both new user and existing user flows
index = child.expect([
    'Enter Samba username:',
    f"Samba user '{username}' already exists. Please enter the password to reset it.",
    'New SMB password:'
])
if index == 0:
    child.sendline(username)
    child.expect('New SMB password:')
elif index == 1:
    child.expect('New SMB password:')
# else index == 2: already at password prompt
child.sendline(password)
child.expect('Retype new SMB password:')
child.sendline(password)
child.expect(pexpect.EOF)
# Do not print or persist anything
