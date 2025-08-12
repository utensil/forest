#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["requests>=2.31.0"]
# ///
"""
Directory Hash and Timestamp Checker
===================================

This script compares two directories for file content (hash) and timestamp mismatches, using jw for hashing and Python for coordination and output parsing.

Usage: uv run ./check-dirs.py <left_dir> <right_dir> [--all-mismatch] [--parallel|-p] [--reuse|-r [HOURS]] [-t N] [-l]

- left_dir: Path to the left/source directory
- right_dir: Path to the right/destination directory
- --all-mismatch: (optional) Show all hash mismatches, not just the first 100
- --parallel, -p: (optional) Hash both directories concurrently
- --reuse, -r [HOURS]: (optional) Reuse recent hash.jw files if found, optionally specify how many hours is considered recent (default: 1 hour if no value given)
- -t N, --progress-interval N: (optional) Progress log interval in seconds (float, default 30; can be 0.001 for high-frequency test)
- -l, --live: (optional) Pass -l to jw for live update (slows down hashing)

The script will:
- Generate hash files for both directories in /tmp/jw/ (or reuse if --reuse is set)
- Compare hashes using jw -D, parse output in Python (not awk)
- Print up to 100 mismatches unless --all-mismatch is specified
- Count and print match/mismatch statistics
- Check file timestamps using the original logic

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
import subprocess
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
    import argparse
    parser = argparse.ArgumentParser(description="Directory hash and timestamp checker")
    parser.add_argument("left_dir", help="Source directory")
    parser.add_argument("right_dir", help="Destination directory")
    parser.add_argument("--all-mismatch", action="store_true", help="Show all hash mismatches (default: only first 100)")
    parser.add_argument("-p", "--parallel", action="store_true", help="Hash both directories concurrently")
    parser.add_argument("-r", "--reuse", nargs="?", const=1, type=int, default=None, help="Reuse recent hash.jw files if found, optionally specify how many hours is considered recent (default: 1 hour if no value given)")
    parser.add_argument('-t', '--progress-interval', type=float, default=30, help="Progress log interval in seconds (default 30, can be 0.001 for test)")
    parser.add_argument('-l', '--live', action='store_true', help="Pass -l to jw for live update (slows down hashing)")
    args = parser.parse_args()

    left_dir = args.left_dir
    right_dir = args.right_dir
    show_all = args.all_mismatch
    parallel = args.parallel
    reuse_hours = args.reuse
    progress_interval = args.progress_interval

    print("[INFO] Checking file content integrity (hash comparison) and file timestamps for mismatches and suspiciously recent files...")
    timestamp = int(time.time())
    left_name = os.path.basename(os.path.abspath(left_dir))
    right_name = os.path.basename(os.path.abspath(right_dir))
    tmpdir = "/tmp/jw"
    os.makedirs(tmpdir, exist_ok=True)

    def find_recent_hash_file(side, name, hours):
        import glob
        pattern = f"{tmpdir}/*-{side}-{name}.hash.jw"
        files = glob.glob(pattern)
        if not files:
            return None
        now = time.time()
        threshold = now - (hours * 3600)
        recent_files = [f for f in files if os.path.getmtime(f) > threshold]
        if not recent_files:
            return None
        # Return the most recent
        return max(recent_files, key=os.path.getmtime)

    # Determine hash file paths (reuse if requested)
    if reuse_hours:
        left_hash = find_recent_hash_file('left', left_name, reuse_hours)
        right_hash = find_recent_hash_file('right', right_name, reuse_hours)
        if left_hash:
            print(f"[INFO] Reusing recent left hash: {left_hash}")
        else:
            left_hash = f"{tmpdir}/{timestamp}-left-{left_name}.hash.jw"
        if right_hash:
            print(f"[INFO] Reusing recent right hash: {right_hash}")
        else:
            right_hash = f"{tmpdir}/{timestamp}-right-{right_name}.hash.jw"
    else:
        left_hash = f"{tmpdir}/{timestamp}-left-{left_name}.hash.jw"
        right_hash = f"{tmpdir}/{timestamp}-right-{right_name}.hash.jw"

    def run_hashing(side, dir_path, hash_path, jw_cmd, parallel_mode, progress_interval):
        print(f"[INFO] Hashing {side}: writing to {hash_path}")
        start_time = time.time()
        proc = subprocess.Popen(jw_cmd, cwd=dir_path, stdout=open(hash_path, "w"))
        check_period = progress_interval
        next_check = start_time + check_period
        finished = False
        while True:
            ret = proc.poll()
            now = time.time()
            if ret is not None:
                finished = True
                break
            if now >= next_check:
                try:
                    wc_out = subprocess.check_output(["wc", "-l", hash_path], text=True).strip()
                    n_lines = int(wc_out.split()[0])
                    elapsed = int(now - start_time)
                    if n_lines == 0:
                        print(f"[INFO] Hashing {side}... {elapsed}s elapsed")
                    else:
                        print(f"[INFO] Hashing {side}... {elapsed}s, {n_lines} files")
                except Exception as e:
                    elapsed = int(now - start_time)
                    print(f"[INFO] Hashing {side}... {elapsed}s elapsed")
                next_check = now + check_period
            # Sleep until next_check or 1s, whichever is sooner
            sleep_time = max(0, min(next_check - time.time(), 1))
            time.sleep(sleep_time)
        duration = int(time.time() - start_time)
        try:
            wc_out = subprocess.check_output(["wc", "-l", hash_path], text=True).strip()
            n_lines = int(wc_out.split()[0])
        except Exception:
            n_lines = 0
        print(f"[INFO] Hashing {side} finished in {duration}s, {n_lines} files")
        return proc

    # Hash both dirs if not reusing
    if not (reuse_hours and os.path.exists(left_hash)) or not (reuse_hours and os.path.exists(right_hash)):
        jw_left_cmd = ["jw", "-c", "."]
        jw_right_cmd = ["jw", "-c", "."]
        if args.live:
            jw_left_cmd.insert(1, "-l")
            jw_right_cmd.insert(1, "-l")

        left_needed = not (reuse_hours and os.path.exists(left_hash))
        right_needed = not (reuse_hours and os.path.exists(right_hash))
        if parallel:
            procs = {}
            if left_needed:
                procs['left'] = subprocess.Popen(jw_left_cmd, cwd=left_dir, stdout=open(left_hash, "w"))
                print(f"[INFO] Hashing left: writing to {left_hash}")
            if right_needed:
                procs['right'] = subprocess.Popen(jw_right_cmd, cwd=right_dir, stdout=open(right_hash, "w"))
                print(f"[INFO] Hashing right: writing to {right_hash}")
            # Progress monitoring loop
            start_times = {k: time.time() for k in procs}
            check_periods = {k: progress_interval for k in procs}
            next_checks = {k: start_times[k] + check_periods[k] for k in procs}
            finished = {k: False for k in procs}
            while not all(finished.values()):
                now = time.time()
                for k, proc in procs.items():
                    if finished[k]:
                        continue
                    ret = proc.poll()
                    if ret is not None:
                        duration = int(time.time() - start_times[k])
                        hash_path = left_hash if k=='left' else right_hash
                        try:
                            wc_out = subprocess.check_output(["wc", "-l", hash_path], text=True).strip()
                            n_lines = int(wc_out.split()[0])
                        except Exception:
                            n_lines = 0
                        print(f"[INFO] Hashing {k} finished in {duration}s, {n_lines} files")
                        finished[k] = True
                        continue
                    if now >= next_checks[k]:
                        hash_path = left_hash if k=='left' else right_hash
                        try:
                            wc_out = subprocess.check_output(["wc", "-l", hash_path], text=True).strip()
                            n_lines = int(wc_out.split()[0])
                            elapsed = int(now - start_times[k])
                            if n_lines == 0:
                                print(f"[INFO] Hashing {k}... {elapsed}s elapsed")
                            else:
                                print(f"[INFO] Hashing {k}... {elapsed}s, {n_lines} files")
                        except Exception as e:
                            elapsed = int(now - start_times[k])
                            print(f"[INFO] Hashing {k}... {elapsed}s elapsed")
                        next_checks[k] = now + check_periods[k]
                # Sleep until next scheduled check or 1s, whichever is sooner
                soonest = min([next_checks[k] - time.time() for k in procs if not finished[k]] + [1])
                sleep_time = max(0, min(soonest, 1))
                time.sleep(sleep_time)
        else:
            if left_needed:
                run_hashing('left', left_dir, left_hash, jw_left_cmd, False, progress_interval)
            if right_needed:
                run_hashing('right', right_dir, right_hash, jw_right_cmd, False, progress_interval)


    # Compare hashes
    proc = subprocess.run(["jw", "-D", left_hash, right_hash], capture_output=True, text=True)
    mismatch_lines = [l for l in proc.stdout.splitlines() if l.startswith("[!(")]
    total = sum(1 for _ in open(left_hash))
    mismatch_count = len(mismatch_lines)
    matched = total - mismatch_count
    print(f"[INFO] {matched} of {total} files have identical hashes.")

    GREEN = '\033[0;32m'
    RED = '\033[0;31m'
    NC = '\033[0m'

    if mismatch_count == 0:
        print(f"[INFO] {GREEN}All files match: hashes are identical.{NC}")
    else:
        print(f"[WARN] Hash mismatch detected.")
        limit = None if show_all else 100
        for line in mismatch_lines[:limit]:
            # Format: [!(...)] <right-hash> != <left-hash> == <file>
            parts = line.split()
            if len(parts) >= 6:
                right_hash_val = parts[1]
                left_hash_val = parts[3]
                file_path = parts[5]
                print(f"[DEBUG] {file_path}|hash-mismatch|{left_hash_val}|{right_hash_val}")
        if not show_all and mismatch_count > 100:
            print(f"[INFO] ... (showing first 100 of {mismatch_count} mismatches, use --all-mismatch to see all)")
        print(f"[INFO] {RED}Hash check failed.{NC}")

    print(f"[INFO] Open {right_hash} to inspect.")

    # Now call the timestamp check logic as before
    left_paths = read_hash_file(left_hash)
    right_paths = read_hash_file(right_hash)
    print(f"[INFO] {len(left_paths)} left paths loaded from {left_hash}")
    print(f"[INFO] {len(right_paths)} right paths loaded from {right_hash}")
    left_sample = sample_paths(left_paths)
    right_sample = sample_paths(right_paths)
    print(f"[INFO] Sampled {len(left_sample)} left and {len(right_sample)} right paths.")

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
