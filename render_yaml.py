#!/usr/bin/env -S uv run
# /// script
# dependencies = [ "pyaml-env" ]
# ///

import os
import sys
import yaml
from pyaml_env import parse_config

if len(sys.argv) != 3:
    print(f"Usage: {sys.argv[0]} <input_yaml.in> <output_yaml>")
    sys.exit(1)

input_path = sys.argv[1]
output_path = sys.argv[2]

config = parse_config(input_path)
os.makedirs(os.path.dirname(output_path), exist_ok=True)
with open(output_path, "w") as f:
    yaml.dump(config, f)
