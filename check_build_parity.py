#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///
"""
Build Output Parity Checker
==========================

This script verifies that `just build` and `mise run build` produce identical output in the `output/` directory.

Usage: uv run check_build_parity.py

- Runs `just build`, saves `output/` as `output.just.<timestamp>/`
- Runs `mise run build`, saves `output/` as `output.mise.<timestamp>/`
- Compares the two directories recursively (ignoring timestamps, symlinks, permissions)
- Reports any differences in file content, missing files, or extra files

AGENT-NOTE: This script is idempotent and safe to run multiple times. It does not modify source files.
"""

import os
import shutil
import subprocess
# AGENT-NOTE: Backup directories output.just.* and output.mise.* are git-ignored via 'output*' in .gitignore (see project root).
import sys
import time
from pathlib import Path
import filecmp

def run_and_backup(build_cmd, backup_dir):
    print(f"Running: {build_cmd}")
    subprocess.run(build_cmd, shell=True, check=True)
    output_dir = Path("output")
    if not output_dir.exists():
        print(f"ERROR: {output_dir} does not exist after build!")
        sys.exit(1)
    if Path(backup_dir).exists():
        shutil.rmtree(backup_dir)
    shutil.copytree(output_dir, backup_dir)
    print(f"Backed up output/ to {backup_dir}")

def compare_dirs(dir1, dir2):
    print(f"Comparing {dir1} <-> {dir2}")
    dcmp = filecmp.dircmp(dir1, dir2)
    differences = False
    if dcmp.left_only:
        print(f"Only in {dir1}: {dcmp.left_only}")
        differences = True
    if dcmp.right_only:
        print(f"Only in {dir2}: {dcmp.right_only}")
        differences = True
    for fname in dcmp.common_files:
        f1 = Path(dir1) / fname
        f2 = Path(dir2) / fname
        if not filecmp.cmp(f1, f2, shallow=False):
            print(f"DIFFERS: {f1} vs {f2}")
            differences = True
    for subdir in dcmp.common_dirs:
        if compare_dirs(Path(dir1)/subdir, Path(dir2)/subdir):
            differences = True
    return differences

def main():
    ts = time.strftime("%Y%m%d-%H%M%S")
    just_backup = f"output.just.{ts}"
    mise_backup = f"output.mise.{ts}"

    run_and_backup("just build", just_backup)
    run_and_backup("mise run build", mise_backup)

    print("\n--- Comparing outputs ---\n")
    differences = compare_dirs(just_backup, mise_backup)
    if not differences:
        print("\n✅ Build outputs are identical!")
        sys.exit(0)
    else:
        print("\n❌ Build outputs differ! See above for details.")
        sys.exit(1)

if __name__ == "__main__":
    main()
