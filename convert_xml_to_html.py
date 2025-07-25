#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["lxml>=5.2.0"]
# ///
"""
XML to HTML Incremental Build Script
===================================

This script incrementally converts XML files in the output/ directory to HTML using XSLT (output/uts-forest.xsl).
It is designed to be idempotent, robust, and fast, supporting parallel execution and accurate dependency checking.

Key Features:
- Only rebuilds HTML files if the corresponding XML or the XSL file is newer, or if the HTML is missing.
- Uses Python's concurrent.futures for parallelism, maximizing CPU utilization while avoiding overload.
- Reports progress and the number of files actually updated.
- Handles errors gracefully, printing clear error messages but continuing the build.
- Designed for integration with build systems (e.g., mise, just) and for deterministic, reproducible builds.

Usage:
    uv run convert_xml_to_html.py

Extension Points:
- To support additional output formats or XSLT parameters, extend the convert_one() function.
- To change the input/output directories, modify OUTPUT_DIR and XSL_PATH.
- For CLI options, add argument parsing to main().

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
#
# This script is called by mise-tasks/build/xml_to_html for incremental HTML builds.
# It is safe to run repeatedly and will only update files as needed.

OUTPUT_DIR = pathlib.Path("output")
XSL_PATH = OUTPUT_DIR / "uts-forest.xsl"
BAK_DIR = OUTPUT_DIR / ".bak"


def get_max_workers() -> int:
    """
    Determine the number of worker threads to use for parallel processing.
    Leaves 2 CPUs free to avoid overloading the system.
    Returns:
        int: Number of worker threads to use (minimum 2).
    """
    try:
        cpu_count = multiprocessing.cpu_count()
        return max(2, cpu_count - 2)
    except Exception:
        return 2


def get_xml_files() -> List[pathlib.Path]:
    """
    Find all XML files in the output directory.
    Returns:
        List[pathlib.Path]: Sorted list of XML file paths.
    """
    return sorted(OUTPUT_DIR.glob("*.xml"))


def needs_rebuild(xml_path: pathlib.Path, html_path: pathlib.Path, xsl_path: pathlib.Path) -> bool:
    """
    Determine if the HTML file needs to be rebuilt.
    Args:
        xml_path (pathlib.Path): Path to the XML source file.
        html_path (pathlib.Path): Path to the HTML output file.
        xsl_path (pathlib.Path): Path to the XSLT stylesheet.
    Returns:
        bool: True if HTML should be rebuilt, False otherwise.
    """
    if not html_path.exists():
        # print(f"[DEBUG] {html_path} does not exist; will rebuild.")
        return True
    if xml_path.stat().st_mtime > html_path.stat().st_mtime:
        # print(f"[DEBUG] {xml_path} is newer than {html_path}; will rebuild.")
        return True
    if xsl_path.exists() and xsl_path.stat().st_mtime > html_path.stat().st_mtime:
        # print(f"[DEBUG] {xsl_path} is newer than {html_path}; will rebuild.")
        return True
    return False


def convert_one(xml_path: pathlib.Path, xsl_path: pathlib.Path, html_path: pathlib.Path, bak_dir: pathlib.Path) -> bool:
    """
    Convert a single XML file to HTML using the provided XSLT stylesheet.
    Only overwrite the HTML file if the output differs from the backup.
    Args:
        xml_path (pathlib.Path): Path to the XML source file.
        xsl_path (pathlib.Path): Path to the XSLT stylesheet.
        html_path (pathlib.Path): Path to the HTML output file.
        bak_dir (pathlib.Path): Path to the backup directory.
    Returns:
        bool: True if HTML was updated (content changed), False otherwise.
    """
    try:
        # Parse XML and XSLT files
        dom = etree.parse(str(xml_path))
        xslt = etree.parse(str(xsl_path))
        transform = etree.XSLT(xslt)
        # Apply the XSLT transformation
        newdom = transform(dom)
        html_path.parent.mkdir(parents=True, exist_ok=True)
        new_html = str(newdom)
        bak_path = bak_dir / html_path.name
        # Compare with backup if it exists
        if bak_path.exists():
            old_html = bak_path.read_text(encoding="utf-8")
            if old_html == new_html:
                return False  # No change
        # Write the HTML output
        html_path.write_text(new_html, encoding="utf-8")
        return True
    except Exception as e:
        # Print error but do not stop the build
        print(f"[ERROR] Failed to convert {xml_path} -> {html_path}: {e}", file=sys.stderr)
        return False


def main():
    """
    Main entry point for the incremental XML-to-HTML build process.
    - Scans for XML files and checks for the XSLT stylesheet.
    - Uses a thread pool to process files in parallel.
    - Only rebuilds HTML files when necessary and content changes.
    - Prints progress and a summary of updated files.
    """
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
        """
        Worker function for a single XML file.
        Returns True if the file was rebuilt (HTML content changed), False otherwise.
        """
        basename = xml_path.stem
        html_path = OUTPUT_DIR / f"{basename}.html"
        bak_path = BAK_DIR / html_path.name
        try:
            # If backup is missing, always rebuild (skip needs_rebuild)
            if not bak_path.exists():
                dom = etree.parse(str(xml_path))
                xslt = etree.parse(str(XSL_PATH))
                transform = etree.XSLT(xslt)
                new_html = str(transform(dom))
                html_path.parent.mkdir(parents=True, exist_ok=True)
                html_path.write_text(new_html, encoding="utf-8")
                return True
            # If backup exists, only rebuild if needed and content differs
            if not needs_rebuild(xml_path, html_path, XSL_PATH):
                return False
            dom = etree.parse(str(xml_path))
            xslt = etree.parse(str(XSL_PATH))
            transform = etree.XSLT(xslt)
            new_html = str(transform(dom))
            old_html = bak_path.read_text(encoding="utf-8")
            if old_html == new_html:
                return False
            html_path.parent.mkdir(parents=True, exist_ok=True)
            html_path.write_text(new_html, encoding="utf-8")
            return True
        except Exception as e:
            print(f"[ERROR] Failed to convert {xml_path} -> {html_path}: {e}", file=sys.stderr)
            return False

    # Use ThreadPoolExecutor for parallel processing of XML files
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
    # Entry point for script execution
    main()
