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
    parser.add_argument('input', metavar='INPUT', help='Input YAML template file (JSON is valid YAML, comments allowed)')
    parser.add_argument('output', metavar='OUTPUT', help='Output file (YAML or JSON)')
    args = parser.parse_args()

    input_path = args.input
    output_path = args.output
    as_json = args.json
    # Default to YAML if neither is set
    if not args.json and not args.yaml:
        as_json = False

    # Always parse as YAML (JSON is valid YAML, comments allowed)
    try:
        config = parse_config(input_path) # , raise_if_na=True)
    except ValueError as e:
        # Print a user-friendly error message
        print(f"[ERROR] {e}", file=sys.stderr)
        print(f"  in file: {input_path}", file=sys.stderr)
        # Try to extract the missing variable name from the error message
        import re
        m = re.search(r'for ([A-Z0-9_]+)', str(e))
        if m:
            var = m.group(1)
            # Print the current value of the offending environment variable
            val = os.environ.get(var)
            print(f"  env {var} value: {repr(val)}", file=sys.stderr)
            # Try to print a snippet of the input file with the offending line
            try:
                with open(input_path) as f:
                    for i, line in enumerate(f, 1):
                        if var in line:
                            print(f"  line {i}: {line.strip()}", file=sys.stderr)
            except Exception:
                pass
        sys.exit(1)

    # Post-process: replace provider.local.models.MODEL_NAME with env value
    try:
        models = config['provider']['local']['models']
        if 'MODEL_NAME' in models:
            model_env = os.environ.get('OPENAI_API_MODEL', 'claude-sonnet-4')
            models[model_env] = models.pop('MODEL_NAME')
    except Exception as e:
        pass  # If structure is not as expected, skip

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        if as_json:
            json.dump(config, f, indent=2, ensure_ascii=False)
        else:
            yaml.dump(config, f, allow_unicode=True)

if __name__ == "__main__":
    main()
