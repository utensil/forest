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
import sys

STACKS_DIR = Path(__file__).parent.parent
OUTPUT_FILE = Path(__file__).parent / "Caddyfile.generated"

site_template = """{stack}.homelab.local {{
    reverse_proxy {stack}:{port}
    tls internal
}}

"""

def extract_ports(port_mapping):
    """
    Given a port mapping (str or int), return (host_port, container_port).
    If only one port is given, both host and container are the same.
    """
    if isinstance(port_mapping, int):
        return port_mapping, port_mapping
    if isinstance(port_mapping, str):
        # Match: [host_ip:]host:container
        m = re.match(r"(?:[0-9.]+:)?([0-9]+):([0-9]+)$", port_mapping)
        if m:
            return int(m.group(1)), int(m.group(2))
        # Match: just a single port
        m = re.match(r"^([0-9]+)$", port_mapping)
        if m:
            return int(m.group(1)), int(m.group(1))
    return None, None

def get_first_ports_from_compose(stack_dir):
    compose_path = None
    for fname in ["compose.yaml", "compose.yml"]:
        candidate = stack_dir / fname
        if candidate.exists():
            compose_path = candidate
            break
    if not compose_path:
        return None, None
    try:
        with open(compose_path) as f:
            data = yaml.safe_load(f)
        services = data.get("services", {})
        if not services:
            return None, None
        first_service = next(iter(services.values()))
        ports = first_service.get("ports", [])
        if not ports:
            return None, None
        return extract_ports(ports[0])
    except Exception as e:
        print(f"Warning: failed to parse {compose_path}: {e}")
    return None, None

def main():
    # print("running...")
    all_entries = list(STACKS_DIR.iterdir())
    # print("All entries in stacks/:", [d.name for d in all_entries])
    stack_names = [d.name for d in all_entries if d.is_dir() and not d.name.startswith('.') and d.name != "caddy"]
    # print("Filtered stack names:", stack_names)
    port_to_stacks = {}
    stack_to_port = {}
    host_port_to_stacks = {}
    for stack in sorted(stack_names):
        stack_dir = STACKS_DIR / stack
        # Unified port extraction
        host_port, container_port = get_first_ports_from_compose(stack_dir)
        # Caddyfile logic (container port)
        if container_port is None:
            print(f"  Warning: No port found for stack '{stack}', skipping Caddyfile rule.")
        else:
            stack_to_port[stack] = container_port
            port_to_stacks.setdefault(container_port, []).append(stack)
        # Host port conflict detection
        if host_port is not None:
            host_port_to_stacks.setdefault(host_port, []).append(stack)
    # Host port conflict detection (unrelated to Caddy, just a warning)
    host_conflicts = {port: stacks for port, stacks in host_port_to_stacks.items() if len(stacks) > 1}
    if host_conflicts:
        print("WARNING: Host port conflicts detected (host port → stacks):")
        for port, stacks in host_conflicts.items():
            print(f"  Host port {port} is used by stacks: {', '.join(stacks)}")
    with open(OUTPUT_FILE, "w") as f:
        for stack in sorted(stack_to_port.keys()):
            port = stack_to_port[stack]
            f.write(site_template.format(stack=stack, port=port))
    print(f"Generated {OUTPUT_FILE} with {len(stack_to_port)} site blocks.")

if __name__ == "__main__":
    main()
