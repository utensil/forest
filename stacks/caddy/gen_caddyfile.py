#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# ///
"""
gen_caddyfile.py
================

Scans the stacks/ directory for stack names and generates a Caddyfile with a block for each stack,
using .homelab.local and tls internal. Output is written to stacks/caddy/Caddyfile.generated.

Usage:
    uv run stacks/caddy/gen_caddyfile.py
"""
import os
from pathlib import Path

STACKS_DIR = Path(__file__).parent.parent
OUTPUT_FILE = Path(__file__).parent / "Caddyfile.generated"

site_template = """{stack}.homelab.local {{
    reverse_proxy {stack}:5001
    tls internal
}}

"""

def main():
    stack_names = [d.name for d in STACKS_DIR.iterdir() if d.is_dir() and not d.name.startswith('.') and d.name != "caddy"]
    with open(OUTPUT_FILE, "w") as f:
        for stack in sorted(stack_names):
            f.write(site_template.format(stack=stack))
    print(f"Generated {OUTPUT_FILE} with {len(stack_names)} site blocks.")

if __name__ == "__main__":
    main()
