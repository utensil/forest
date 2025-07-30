#!/usr/bin/env -S uv run
# /// script
# dependencies = [ "pyaml-env", "pyyaml", "json5" ]
# ///
"""
Render YAML or JSON from a template with environment variable substitution.

Usage:
  render_yaml.py [--json|-j|--yaml|-y] <input_yaml.in> <output_file>
  render_yaml.py --help|-h

Options:
  --json, -j   Output JSON instead of YAML
  --yaml, -y   Output YAML (default)
  --help, -h   Show this help message

Examples:
  render_yaml.py config.yaml.in config.yaml
  render_yaml.py --json config.yaml.in config.json
"""
import os
import sys
import argparse
import yaml
import json
from pyaml_env import parse_config

def main():
    parser = argparse.ArgumentParser(
        description="Render YAML or JSON from a template with env substitution.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Examples:\n  render_yaml.py config.yaml.in config.yaml\n  render_yaml.py --json config.yaml.in config.json"
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--json', '-j', action='store_true', help='Output JSON instead of YAML')
    group.add_argument('--yaml', '-y', action='store_true', help='Output YAML (default)')
    parser.add_argument('input', metavar='INPUT', help='Input YAML template file')
    parser.add_argument('output', metavar='OUTPUT', help='Output file (YAML or JSON)')
    args = parser.parse_args()

    input_path = args.input
    output_path = args.output
    as_json = args.json
    # Default to YAML if neither is set
    if not args.json and not args.yaml:
        as_json = False

    config = parse_config(input_path)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        if as_json:
            json.dump(config, f, indent=2, ensure_ascii=False)
        else:
            yaml.dump(config, f, allow_unicode=True)

if __name__ == "__main__":
    main()
