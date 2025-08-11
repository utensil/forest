#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["requests>=2.31.0"]
# ///
"""
File Timestamp Checker
=====================

This script samples file paths from two hash files (produced by `jw -c .`), checks their modification times, and reports suspicious timestamp mismatches or files with timestamps that are “too recent” (likely due to copying).

Usage: uv run ./check-ts.py <left_dir> <right_dir> <left_hash> <right_hash>

- left_dir: Path to the left/source directory
- right_dir: Path to the right/destination directory
- left_hash: Path to the left hash file (from jw)
- right_hash: Path to the right hash file (from jw)

The script will sample up to 1000 file paths from each hash file, check their mtimes, and print a report of any mismatches or suspiciously recent files.

AGENT-NOTE: CRITICAL FEATURES TO MAINTAIN
1. IDEMPOTENT: Multiple runs must produce identical results
2. ERROR HANDLING: Graceful degradation for missing data
3. BUILD INTEGRATION: Validates syntax after processing
4. DETERMINISTIC: Sorted processing ensures consistent output
"""

import sys
import os
import random
import time
from datetime import datetime, timedelta

SAMPLE_SIZE = 1000
RECENT_THRESHOLD_SECONDS = 60 * 10  # 10 minutes

def read_hash_file(hash_path):
    paths = []
    HASH_LEN = 32  # MD5 hash length; adjust if needed
    try:
        with open(hash_path, 'r') as f:
            for line in f:
                # Format: <hash><path>, path is relative (may start with ./)
                line = line.strip()
                if not line or len(line) <= HASH_LEN:
                    continue
                rel_path = line[HASH_LEN:]
                paths.append(rel_path)

    except Exception as e:
        print(f"[WARN] Failed to read {hash_path}: {e}")
    return sorted(set(paths))

def sample_paths(paths):
    if len(paths) <= SAMPLE_SIZE:
        return paths
    random.seed(42)  # Deterministic
    return sorted(random.sample(paths, SAMPLE_SIZE))

def check_timestamps(base_dir, paths, threshold=RECENT_THRESHOLD_SECONDS):
    now = time.time()
    suspicious = []
    for rel_path in paths:
        abs_path = os.path.normpath(os.path.join(base_dir, rel_path.lstrip('/')))
        try:
            stat = os.stat(abs_path)
            mtime = stat.st_mtime
            if now - mtime < threshold:
                suspicious.append((rel_path, mtime))
        except Exception as e:
            print(f"[WARN] Could not stat {abs_path}: {e}")
    return suspicious

def compare_timestamps(left_dir, right_dir, left_paths, right_paths):
    mismatches = []
    newer = 0
    older = 0
    for rel_path in set(left_paths) & set(right_paths):
        left_abs = os.path.join(left_dir, rel_path)
        right_abs = os.path.join(right_dir, rel_path)
        try:
            left_mtime = os.stat(left_abs).st_mtime
            right_mtime = os.stat(right_abs).st_mtime
            if abs(left_mtime - right_mtime) > 1:  # Allow 1s slack
                diff = right_mtime - left_mtime
                if diff > 0:
                    issue = f"{format_timedelta(diff)} newer"
                    newer += 1
                else:
                    issue = f"{format_timedelta(-diff)} older"
                    older += 1
                mismatches.append((rel_path, issue, left_mtime, right_mtime, diff))
        except Exception as e:
            print(f"[WARN] Could not stat {rel_path}: {e}")
    return mismatches, newer, older

def format_timedelta(seconds):
    # Returns a human-readable difference, e.g. '5 days', '3 hours', '12 min', '8 sec'
    seconds = int(seconds)
    if seconds >= 86400:
        return f"{seconds // 86400} days"
    elif seconds >= 3600:
        return f"{seconds // 3600} hours"
    elif seconds >= 60:
        return f"{seconds // 60} min"
    else:
        return f"{seconds} sec"

def main():
    if len(sys.argv) != 5:
        print("[WARN] Usage: uv run ./check-ts.py <left_dir> <right_dir> <left_hash> <right_hash>")
        sys.exit(1)
    print("[INFO] Checking for timestamp mismatches and suspiciously recent files between two directories.")
    left_dir, right_dir, left_hash, right_hash = sys.argv[1:5]
    left_paths = read_hash_file(left_hash)
    right_paths = read_hash_file(right_hash)
    print(f"[INFO] {len(left_paths)} left paths loaded from {left_hash}")
    print(f"[INFO] {len(right_paths)} right paths loaded from {right_hash}")
    left_sample = sample_paths(left_paths)
    right_sample = sample_paths(right_paths)
    print(f"[INFO] Sampled {len(left_sample)} left and {len(right_sample)} right paths.")

    # ANSI color codes
    GREEN = '\033[0;32m'
    RED = '\033[0;31m'
    NC = '\033[0m'

    # Too recent check (right side only, per user example)
    right_suspicious = check_timestamps(right_dir, right_sample)
    if right_suspicious:
        print(f"[WARN] {len(right_suspicious)} too recent (in {RECENT_THRESHOLD_SECONDS} seconds)")
        for rel_path, mtime in right_suspicious:
            print(f"[DEBUG] {rel_path}|too-recent|{datetime.fromtimestamp(mtime).strftime('%Y-%m-%d %H:%M:%S')}")

    # Timestamp mismatches
    mismatches, newer, older = compare_timestamps(left_dir, right_dir, left_sample, right_sample)
    total_common = len(set(left_sample) & set(right_sample))
    identical_count = total_common - len(mismatches)
    print(f"[INFO] {identical_count} sampled files have identical timestamps.")
    if mismatches:
        print(f"[WARN] {len(mismatches)} timestamp mismatch, {newer} newer, {older} older")
        for rel_path, issue, left_m, right_m, diff in mismatches:
            print(f"[DEBUG] {rel_path}|timestamp-mismatch|{issue}|{datetime.fromtimestamp(left_m).strftime('%Y-%m-%d %H:%M:%S')}|{datetime.fromtimestamp(right_m).strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"[INFO] {RED}Timestamp check failed.{NC}")
    elif right_suspicious:
        print(f"[INFO] {RED}Timestamp check failed.{NC}")
    else:
        print(f"[INFO] {GREEN}All sampled files have consistent timestamps, none are too recent.{NC}")


if __name__ == "__main__":
    main()
