#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["pexpect>=4.8.0"]
# ///
"""
Automate interaction with /start-samba.sh using pexpect.
Usage: python init_user.py <username> <password>
"""

import sys
import pexpect

if len(sys.argv) != 3:
    print("Usage: python init_user.py <username> <password>")
    sys.exit(1)

username, password = sys.argv[1], sys.argv[2]

child = pexpect.spawn('/start-samba.sh')
child.expect('Enter Samba username:')
child.sendline(username)
child.expect('New SMB password:')
child.sendline(password)
child.expect('Retype new SMB password:')
child.sendline(password)
child.expect(pexpect.EOF)
print(child.before.decode(errors='ignore'))
