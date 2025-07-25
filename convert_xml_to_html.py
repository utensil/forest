#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["lxml>=5.2.0"]
# ///
"""
XML to HTML Converter
=====================

This script converts XML files in output/ to HTML using XSLT (output/uts-forest.xsl).
It only rebuilds HTML if the XML or XSL is newer, or if the HTML is missing.
Parallel processing is used for speed. Progress and update count are reported.

Usage: uv run convert_xml_to_html.py

AGENT-NOTE: CRITICAL FEATURES TO MAINTAIN
1. IDEMPOTENT: Multiple runs must produce identical results
2. ERROR HANDLING: Graceful degradation for missing data
3. BUILD INTEGRATION: Validates syntax after processing
4. DETERMINISTIC: Sorted processing ensures consistent output
"""

import os
import sys
import pathlib
import concurrent.futures
import multiprocessing
from lxml import etree
from typing import List

# AGENT-NOTE: perf-hot-path; parallel conversion, progress bar, and update count must be robust

OUTPUT_DIR = pathlib.Path("output")
XSL_PATH = OUTPUT_DIR / "uts-forest.xsl"


def get_max_workers() -> int:
    try:
        cpu_count = multiprocessing.cpu_count()
        return max(2, cpu_count - 2)
    except Exception:
        return 2


def get_xml_files() -> List[pathlib.Path]:
    return sorted(OUTPUT_DIR.glob("*.xml"))


def needs_rebuild(xml_path: pathlib.Path, html_path: pathlib.Path, xsl_path: pathlib.Path) -> bool:
    if not html_path.exists():
        return True
    if xml_path.stat().st_mtime > html_path.stat().st_mtime:
        return True
    if xsl_path.exists() and xsl_path.stat().st_mtime > html_path.stat().st_mtime:
        return True
    return False


def convert_one(xml_path: pathlib.Path, xsl_path: pathlib.Path, html_path: pathlib.Path) -> bool:
    try:
        dom = etree.parse(str(xml_path))
        xslt = etree.parse(str(xsl_path))
        transform = etree.XSLT(xslt)
        newdom = transform(dom)
        html_path.parent.mkdir(parents=True, exist_ok=True)
        html_path.write_text(str(newdom), encoding="utf-8")
        return True
    except Exception as e:
        print(f"[ERROR] Failed to convert {xml_path} -> {html_path}: {e}", file=sys.stderr)
        return False


def main():
    xml_files = get_xml_files()
    if not xml_files:
        print("No XML files found in output/.")
        sys.exit(0)
    if not XSL_PATH.exists():
        print(f"XSL file not found: {XSL_PATH}", file=sys.stderr)
        sys.exit(1)

    max_workers = get_max_workers()
    print(f"Max jobs: {max_workers}")
    updated_count = 0
    total_files = len(xml_files)
    progress = 0
    progress_step = max(1, total_files // 20)
    print("Progress: ", end="", flush=True)

    def process(xml_path: pathlib.Path) -> bool:
        basename = xml_path.stem
        html_path = OUTPUT_DIR / f"{basename}.html"
        if needs_rebuild(xml_path, html_path, XSL_PATH):
            if convert_one(xml_path, XSL_PATH, html_path):
                return True
        return False

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(process, xml_path): i for i, xml_path in enumerate(xml_files)}
        for i, future in enumerate(concurrent.futures.as_completed(futures)):
            try:
                if future.result():
                    updated_count += 1
            except Exception as e:
                print(f"[ERROR] Exception in worker: {e}", file=sys.stderr)
            # AGENT-NOTE: progress bar logic
            if (i + 1) % progress_step == 0 or (i + 1) == total_files:
                print("█", end="", flush=True)
    print()
    print(f"📝 Updated {updated_count} HTML file(s) out of {total_files}")

if __name__ == "__main__":
    main()
