#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["pyyaml>=6.0.0"]
# ///
"""
gen_caddyfile.py
================

Scans the stacks/ directory for stack names and generates a Caddyfile with a block for each stack,
using .homelab.local and tls internal. Output is written to stacks/caddy/Caddyfile.generated.

Port detection:
- For each stack, if a compose.yaml or compose.yml exists, the script uses the first port mapping of the first service as the proxy target port.
- If no port is found, defaults to 5001.
- This allows stacks to expose different ports without manual overrides.

Usage:
    uv run stacks/caddy/gen_caddyfile.py
"""
import os
from pathlib import Path
import yaml
import re

STACKS_DIR = Path(__file__).parent.parent
OUTPUT_FILE = Path(__file__).parent / "Caddyfile.generated"

# AGENT-NOTE: Added per-stack port override support
PORT_OVERRIDES = {
    "kopia": 51515,
}

site_template = """{stack}.homelab.local {{
    reverse_proxy {stack}:{port}
    tls internal
}}

"""

def get_first_port_from_compose(stack_dir):
    compose_path = None
    for fname in ["compose.yaml", "compose.yml"]:
        candidate = stack_dir / fname
        if candidate.exists():
            compose_path = candidate
            break
    if not compose_path:
        return None
    try:
        with open(compose_path) as f:
            data = yaml.safe_load(f)
        # Find the first service
        services = data.get("services", {})
        if not services:
            return None
        first_service = next(iter(services.values()))
        ports = first_service.get("ports", [])
        if not ports:
            return None
        # ports can be in form "host:container" or just "port"
        first_port = ports[0]
        if isinstance(first_port, int):
            return first_port
        if isinstance(first_port, str):
            # Try to extract the container port (after the colon)
            m = re.match(r"(?:[0-9.]+:)?([0-9]+)", first_port)
            if m:
                return int(m.group(1))
    except Exception as e:
        print(f"Warning: failed to parse {compose_path}: {e}")
    return None

def main():
    stack_names = [d.name for d in STACKS_DIR.iterdir() if d.is_dir() and not d.name.startswith('.') and d.name != "caddy"]
    with open(OUTPUT_FILE, "w") as f:
        for stack in sorted(stack_names):
            stack_dir = STACKS_DIR / stack
            port = get_first_port_from_compose(stack_dir)
            if port is None:
                port = 5001
            f.write(site_template.format(stack=stack, port=port))
    print(f"Generated {OUTPUT_FILE} with {len(stack_names)} site blocks.")

if __name__ == "__main__":
    main()
