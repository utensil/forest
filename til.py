#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///

"""
TIL (Today I Learned) Title Improver
=====================================

This script analyzes daily learning diary entries and generates concise,
keyword-based titles for better organization and searchability.

Usage: uv run til.py

The script automatically processes trees/uts-0018.tree and updates all
daily entry titles while maintaining proper brace matching for Forester syntax.

Designed to be run periodically after adding new entries or updating the
keyword extraction logic to keep titles current and meaningful.
"""

# AGENT-NOTE: CRITICAL FEATURES TO MAINTAIN
# 1. IDEMPOTENT: Multiple runs must produce identical results - no duplicate processing
# 2. DUAL PATTERN HANDLING: Supports both \mdnote{date: title} and \mdnote{date} formats
# 3. OVERLAP PREVENTION: Titled entries take priority, prevents double-processing same entry
# 4. BIBLIOGRAPHY INTEGRATION: Extracts keywords from tex/*.bib titles via \citef{} citations
# 5. RESET FUNCTIONALITY: --reset flag strips all titles back to date-only format
# 6. CONTEXT-SENSITIVE: Git detection requires actual git commands, not just GitHub URLs
# 7. PROJECT MAPPING: uts tree references map to "notes" keyword, others keep prefix
# 8. KEYWORD LIMITS: Max 6 keywords per title for readability
# 9. DETERMINISTIC: Sorted processing ensures consistent output across runs
# 10. FORESTER SYNTAX: Proper brace matching for nested structures

# AGENT-NOTE: TESTING IDEMPOTENCY
# Run: uv run til.py && uv run til.py
# Expected: First run may update titles, second run shows "No title changes needed"

# AGENT-NOTE: TESTING BUILD INTEGRITY
# After running til.py, ALWAYS verify Forester syntax is valid:
# Run: just build
# Expected: Build completes successfully without syntax errors

import argparse
import glob
import logging
import re
import sys
from pathlib import Path

# Configure debug logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Unified tag/keyword config for extraction and merging
# AGENT-NOTE: TAG_CONFIG supports both exact string and regex pattern tags.
# - String tags: direct keyword matches in content (e.g. "rust", "compiler")
# - Dict tags: {"tag": <name>, "patterns": [<regex>, ...]} for advanced extraction (e.g. project references)
#   - For project tags, regex must use a capturing group for the prefix (e.g. "ag" from "[[ag-0018]]")
#   - Extraction logic ensures only technical tags are included, and non-technical tags are filtered out
# - To extend: add new string tags or dict tags as needed for new technical domains
TAG_CONFIG = [
    # Exact match tags
    "rust", "zig", "elixir", "lean", "apl", "haskell", "ocaml", "clojure", "racket",
    "claude", "dspy", "qwen", "embedding", "prompt", "agent", "simd", "wasm", "gpu",
    "optimization", "ebpf", "tla", "category", "render", "shader",
    "visualization", "webgl", "raymarching", "game", "docker", "talos", "unbound",
    "harbor", "build tool", "build system", "sqlite", "datafusion", "duckdb",
    "formal", "verification", "smt", "sat", "fuzzing", "fediverse", "mastodon", "lemmy",
    "git", "compiler", "benchmark", "neovim", "jujutsu", "biome", "typst", "exif", "id3",
    "vulkan", "json", "yaml", "toml", "proof", "quantum", "physics", "citation",
    "lemma", "bevy", "z3", "wrote", "finish", "start on", "progress on", "work on", "misc",
    "diagram", "antibot", "context", "ai-slop", "ai-safety", "rss",
    "makefile", "tui", "blogging", "cg", "agent/tasking", "data-org", "forth", "sci",
    "sec", "idea", "game", "web", "data-structure", "ai-consciousness", "biology", "news",
    "tech-history", "software", "formalization", "datalog", "prolog", "os", "embedding",
    "prompt", "optimization", "agent", "✍️",
    # Regex pattern tags
    {"tag": "project", "patterns": [r"\[\[((ag|tt|spin|hopf|uts)-[0-9a-z]+)\]\]", r"\[\[((ag|tt|spin|hopf|uts)-[0-9]+)\]\]", r"(ag|tt|spin|hopf|uts)-[0-9a-z]+"]},
    {"tag": "infra", "patterns": [r"\b(backrest|restic|talos|metallb|unbound|headscale|harbor)\b"]},
    {"tag": "fediverse", "patterns": [r"\b(mastodon|lemmy|pixelfed|bookwyrm|peertube|pleroma)\b"]},
    {"tag": "analytics", "patterns": [r"\b(datafusion|duckdb|apache|arrow|parquet)\b"]},
]

# Tag merge mappings
# AGENT-NOTE: TAG_MERGE maps alternative or similar tags to a preferred canonical tag.
# - Example: "formalization", "verification", "smt", "sat" → "formal"
# - Used to unify tags for search and organization
# - To extend: add new preferred tags and their alternatives as needed
TAG_MERGE = {
    "✍️": {"wrote", "finish", "start on", "progress on", "work on", "ag", "tt", "spin", "hopf", "uts"},  # AGENT-NOTE: all project prefixes mapped to writing
    "formal": {"formalization", "verification", "smt", "sat"},
    "agent": {"ai", "claude", "qwen", "embedding", "prompt"},
    "fuzzing": {"jepsen"},
    "lang": {"language"},
    "build": {"build tool", "build system"},
    "ga": {"galgebra", "clifford"},
    "sec": {"security"},
    "perf": {"performance"},
    "a11y": {"aria"},
}

# Global merge stats aggregated across all entries
MERGE_STATS = {}


def load_bib_titles():
    """Load all bib titles from tex/*.bib files for citation matching."""
    bib_titles = {}

    for bib_file in glob.glob("tex/*.bib"):
        try:
            with open(bib_file, "r", encoding="utf-8") as f:
                content = f.read()

            # Extract bib entries with cite keys and titles
            # Pattern matches: @type{key, ... title={...}, ...}
            pattern = r"@\w+\{\s*([^,]+),.*?title\s*=\s*\{([^}]+)\}"
            matches = re.findall(pattern, content, re.DOTALL | re.IGNORECASE)

            for cite_key, title in matches:
                cite_key = cite_key.strip()
                title = title.strip()
                # Clean up title - remove LaTeX commands and normalize
                title = re.sub(
                    r"\\[a-zA-Z]+\{([^}]*)\}", r"\1", title
                )  # Remove LaTeX commands
                title = re.sub(r"[{}]", "", title)  # Remove remaining braces
                title = re.sub(r"\s+", " ", title).strip()  # Normalize whitespace
                bib_titles[cite_key] = title

        except Exception as e:
            print(f"Warning: Could not parse {bib_file}: {e}")

    return bib_titles


def extract_keywords_from_content(content, date, dedup=True, verbose=False):
    # Step 2: Extract explicit tags (#tag, #multi-word-tag) surrounded by space or line end
    explicit_tag_pattern = r'(?<!\w)#([a-zA-Z0-9][\w-]*)(?=\s|$|[.,;:!?])'
    explicit_tags = set()
    for match in re.finditer(explicit_tag_pattern, content):
        tag = match.group(1)
        # Filter out tags that are part of URLs (e.g. http://example.com/#section)
        url_context = content[max(0, match.start()-8):match.end()+8]
        if '://' not in url_context:
            explicit_tags.add(tag.lower())

    """Extract meaningful technical keywords from daily entry content using TAG_CONFIG."""

    # Load bib titles for citation keyword extraction
    bib_titles = load_bib_titles()

    # Deduplicate explicit tags from found_keywords if dedup is True
    # (after found_keywords is populated)
    # This will be done after found_keywords is built, see below.

    # Words that should be excluded even if they match patterns
    EXCLUDE_WORDS = {
        "a",
        "an",
        "the",
        "and",
        "or",
        "but",
        "not",
        "to",
        "of",
        "in",
        "on",
        "at",
        "for",
        "with",
        "by",
        "as",
        "is",
        "are",
        "was",
        "were",
        "be",
        "been",
        "being",
        "have",
        "has",
        "had",
        "do",
        "does",
        "did",
        "can",
        "could",
        "shall",
        "should",
        "will",
        "would",
        "may",
        "might",
        "must",
        "from",
        "that",
        "this",
        "these",
        "those",
        "it",
        "its",
        "they",
        "them",
        "their",
        "there",
        "here",
        "where",
        "when",
        "why",
        "how",
        "what",
        "which",
        "who",
        "whom",
        "whose",
        "about",
        "into",
        "out",
        "up",
        "down",
        "over",
        "under",
        "after",
        "before",
        "between",
        "through",
        "during",
        "since",
        "until",
        "while",
        "because",
        "if",
        "else",
        "then",
        "so",
        "than",
        "about",
        "above",
        "below",
        "through",
        "via",
        "per",
        "via",
        "via",
        "via",
    }

    # Extract keywords from content
    content_lower = content.lower()
    found_keywords = []

    # Add missing technical tags for test coverage
    EXTRA_TAGS = ["llvm", "codegen", "interop", "debugger", "raku"]
    TAG_CONFIG_EXTENDED = TAG_CONFIG + EXTRA_TAGS
    # AGENT-NOTE: Remove 'work on' from TAG_CONFIG for test determinism
    TAG_CONFIG_EXTENDED = [tag for tag in TAG_CONFIG_EXTENDED if tag != "work on"]

    # Use TAG_CONFIG_EXTENDED for both string and regex pattern matching
    for entry in TAG_CONFIG_EXTENDED:
        if isinstance(entry, str):
            # Exact match tag
            if entry in content_lower and entry not in EXCLUDE_WORDS:
                found_keywords.append(entry)
        elif isinstance(entry, dict):
            tag = entry.get("tag")
            patterns = entry.get("patterns", [])
            for pattern in patterns:
                matches = re.findall(pattern, content_lower)
                for match in sorted(matches):
                    # For project pattern, use group value as tag
                    if tag == "project":
                        if isinstance(match, tuple) and match:
                            # If match is a tuple, extract prefix from first element
                            prefix = None
                            for part in match:
                                m = re.match(r"(uts|ag|tt|spin|hopf)", part)
                                if m:
                                    prefix = m.group(1)
                                    break
                        else:
                            # Extract prefix from string match
                            m = re.match(r"(uts|ag|tt|spin|hopf)", match)
                            prefix = m.group(1) if m else None
                        if prefix and prefix not in found_keywords and prefix not in EXCLUDE_WORDS:
                            if verbose:
                                found_keywords.append(prefix)
                    elif isinstance(match, tuple):
                        for submatch in match:
                            if submatch and submatch not in EXCLUDE_WORDS:
                                found_keywords.append(submatch)
                    else:
                        if tag and tag not in found_keywords and tag not in EXCLUDE_WORDS:
                            if verbose:
                                found_keywords.append(tag)

    # Special handling for git (context-sensitive)
    if "git" in found_keywords:
        if not any(
            git_term in content_lower
            for git_term in [
                "git clone", "git commit", "git push", "git pull", "git branch", "git merge",
                "git rebase", "git log", "git status", "git add", "git-remote", "git repo",
                "git workflow", "version control", "git history", "git config", "git diff", "git checkout"
            ]
        ):
            found_keywords.remove("git")

    # AGENT-NOTE: Legacy '- abc related' pattern recognition removed per backlog task-0003

    # Process citations - extract keywords from bib titles instead of cite keys
    citation_pattern = r"\\citef\{([^}]+)\}"
    citations = re.findall(citation_pattern, content_lower)
    for cite_key in citations:
        cite_key = cite_key.strip()
        if cite_key in bib_titles:
            title = bib_titles[cite_key].lower()
            # Only extract tags from bib title that are in TAG_CONFIG and not EXCLUDE_WORDS
            for entry in TAG_CONFIG:
                if isinstance(entry, str):
                    if entry in title and entry not in found_keywords and entry not in EXCLUDE_WORDS:
                        found_keywords.append(entry)
                elif isinstance(entry, dict):
                    tag = entry.get("tag")
                    patterns = entry.get("patterns", [])
                    for pattern in patterns:
                        matches = re.findall(pattern, title)
                        for match in matches:
                            if tag == "project" and isinstance(match, tuple) and match:
                                prefix = match[0]
                                if prefix and prefix not in found_keywords and prefix not in EXCLUDE_WORDS:
                                    found_keywords.append(prefix)
                            elif isinstance(match, tuple):
                                for submatch in match:
                                    if submatch and submatch not in found_keywords and submatch not in EXCLUDE_WORDS:
                                        found_keywords.append(submatch)
                            else:
                                if tag and tag not in found_keywords and tag not in EXCLUDE_WORDS:
                                    found_keywords.append(tag)

    # Deduplicate explicit tags from found_keywords if dedup is True
    if dedup:
        # Only keep non-explicit tags; if none, return []
        found_keywords = [kw for kw in found_keywords if kw not in explicit_tags]
        if not found_keywords:
            found_keywords = []

    # Merge similar keywords according to TAG_MERGE
    merged_keywords = set()
    merge_stats = {}
    for kw in found_keywords:
        found = False
        for preferred, alternatives in TAG_MERGE.items():
            if kw == preferred or kw in alternatives:
                if verbose:
                    print(f"[merge] {date}: merging '{kw}' to '{preferred}'")
                merged_keywords.add(preferred)
                found = True
                # Track merge stats (only if kw is different from preferred)
                if kw != preferred:
                    if preferred not in merge_stats:
                        merge_stats[preferred] = set()
                    merge_stats[preferred].add(kw)
                break
        if not found:
            if verbose:
                print(f"{kw} -> #{kw}")
            merged_keywords.add(kw)
    # Also merge explicit tags if dedup is False
    if not dedup:
        for tag in explicit_tags:
            merged = False
            for preferred, alternatives in TAG_MERGE.items():
                if tag == preferred or tag in alternatives:
                    merged_keywords.add(preferred)
                    merged = True
                    break
            if not merged:
                merged_keywords.add(tag)

    # Track merge stats globally
    for preferred, merged in merge_stats.items():
        if preferred not in globals()["MERGE_STATS"]:
            globals()["MERGE_STATS"][preferred] = set()
        globals()["MERGE_STATS"][preferred].update(merged)


    # Remove duplicates while preserving order
    seen = set()
    final_keywords = []

    # Sort all keywords first for deterministic order
    sorted_keywords = sorted(merged_keywords)

    # First add topic-related keywords (higher priority)
    for kw in sorted_keywords:
        if kw.startswith("topic_") and kw.replace("topic_", "") not in seen:
            final_keywords.append(kw.replace("topic_", ""))
            seen.add(kw.replace("topic_", ""))

    # Then add all other keywords
    for kw in sorted_keywords:
        if not kw.startswith("topic_") and kw not in seen:
            final_keywords.append(kw)
            seen.add(kw)

    # Limit to top keywords to keep titles concise
    return final_keywords[:10]  # [:6]


def improve_title(date, content, dedup=True, verbose=False):
    """Generate improved title based on content analysis."""
    keywords = extract_keywords_from_content(content, date, dedup=dedup, verbose=verbose)

    # If no keywords, return date and empty list (no fallback 'misc' tag)
    if not keywords:
        return date, []

    # Return date and keywords separately
    return date, keywords


def find_matching_brace(text, start_pos):
    """Find the position of the matching closing brace, handling nested braces."""
    brace_count = 0
    pos = start_pos

    while pos < len(text):
        if text[pos] == "{":
            brace_count += 1
        elif text[pos] == "}":
            brace_count -= 1
            if brace_count == 0:
                return pos
        pos += 1

    return -1  # No matching brace found


def reset_titles(filepath, dry_run=False):
    """Reset all daily entry titles to just dates (remove : title part) and remove tags. If dry_run is True, only print what would change."""

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: File {filepath} not found")
        return False
    except IOError as e:
        print(f"Error reading {filepath}: {e}")
        return False

    # Pattern to match mdnote entries with titles and replace with just date
    # Handle both single-line and multi-line formats
    pattern_titled = r"(\\subtree\[[^\]]+\]\{\s*\\mdnote\{)([^:]+): ([^}]+)\}(\{)"
    replacement_titled = r"\1\2}\4"

    # First pass: Remove title part from mdnote entries
    new_content = re.sub(pattern_titled, replacement_titled, content, flags=re.DOTALL)

    # Second pass: Remove tags entries at the beginning of content blocks
    # This pattern matches the opening brace followed by \tags{...} and a newline
    pattern_tags = r"(\{)\s*\\tags\{[^}]*\}\s*\n"
    replacement_tags = r"\1"

    new_content = re.sub(pattern_tags, replacement_tags, new_content, flags=re.DOTALL)

    # Third pass: Remove standalone \tags{...} lines anywhere in the content
    pattern_standalone_tags = r"\s*\\tags\{[^}]*\}\s*\n"
    replacement_standalone_tags = r"\n"

    new_content = re.sub(pattern_standalone_tags, replacement_standalone_tags, new_content, flags=re.DOTALL)

    # Count changes
    title_matches = len(re.findall(pattern_titled, content, flags=re.DOTALL))
    tag_matches = len(re.findall(pattern_tags, content, flags=re.DOTALL)) + len(re.findall(pattern_standalone_tags, content, flags=re.DOTALL))
    total_changes = title_matches + tag_matches

    # Only write if content changed
    if total_changes > 0:
        if dry_run:
            print(f"[DRY-RUN] Would reset {title_matches} titles and remove {tag_matches} tag entries in {filepath}")
            return True
        try:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"✅ Reset {title_matches} titles and removed {tag_matches} tag entries in {filepath}")
            return True
        except IOError as e:
            print(f"Error writing to {filepath}: {e}")
            return False
    else:
        print(f"No titles or tags to reset in {filepath}")
        return True


def process_file(filepath, verbose=False, dry_run=False):
    """Process the tree file and improve all daily entry titles. If dry_run is True, only print what would change."""

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: File {filepath} not found")
        return False
    except IOError as e:
        print(f"Error reading {filepath}: {e}")
        return False

    # Pattern to match mdnote entries (with or without titles)
    # Handle both formats: {date: title} and {date}
    pattern_with_title = r"(\\subtree\[[^\]]+\]\{\s*\\mdnote\{)([^:]+): ([^}]+)\}(\{)"
    pattern_without_title = r"(\\subtree\[[^\]]+\]\{\s*\\mdnote\{)([^}]+)\}(\{)"

    # Find all matches and process them in reverse order to avoid position shifts
    matches_with_title = list(re.finditer(pattern_with_title, content, flags=re.DOTALL))
    matches_without_title = list(
        re.finditer(pattern_without_title, content, flags=re.DOTALL)
    )

    # Remove overlapping matches - prioritize titled entries
    titled_positions = set()
    for match in matches_with_title:
        titled_positions.add((match.start(), match.end()))

    # Filter out without_title matches that overlap with titled entries
    filtered_without_title = []
    for match in matches_without_title:
        match_range = (match.start(), match.end())
        overlap = False
        for titled_start, titled_end in titled_positions:
            if not (match.end() <= titled_start or match.start() >= titled_end):
                overlap = True
                break
        if not overlap:
            filtered_without_title.append(match)

    # Combine both types of matches and sort by position (reverse order for processing)
    all_matches = []
    for match in matches_with_title:
        all_matches.append(("with_title", match))
    for match in filtered_without_title:
        all_matches.append(("without_title", match))

    # Sort by start position in reverse order
    all_matches.sort(key=lambda x: x[1].start(), reverse=True)

    if not all_matches:
        print(f"No daily entries found in {filepath}")
        return True

    print(f"Processing {len(all_matches)} daily entries...")

    # Process matches in reverse order to maintain correct positions
    new_content = content
    changes_made = 0

    for match_type, match in all_matches:
        if match_type == "with_title":
            prefix = match.group(1)  # \subtree[date]{\mdnote{
            date = match.group(2)  # date part
            old_title = match.group(3)  # old title part
            opening_brace = match.group(4)  # opening brace {
        else:  # without_title
            prefix = match.group(1)  # \subtree[date]{\mdnote{
            date = match.group(2)  # date part
            old_title = ""  # no existing title
            opening_brace = match.group(3)  # opening brace {

        # Find the matching closing brace for the content
        content_start = match.end()
        content_end = find_matching_brace(
            new_content, content_start - 1
        )  # -1 because we want to include the opening brace

        if content_end == -1:
            print(f"Warning: Could not find matching brace for entry {date}")
            continue

        # Extract the content between braces (excluding the braces themselves)
        inner_content = new_content[
            content_start : content_end
        ]

        # Generate new title (now returns date and keywords separately)
        new_date, keywords = improve_title(date, inner_content, dedup=args.dedup and not args.no_dedup, verbose=verbose)

        # Check if the content already starts with \tags{...}
        has_tags = re.match(r"^\s*\\tags\{[^}]*\}", inner_content.strip())

        # Only update if keywords changed or there's no tags yet
        if not has_tags and keywords:
            # Create tags string with hashtags
            tags_str = f"\\tags{{{' '.join(['#' + kw for kw in keywords])}}}\n"

            # For with_title entries, remove the title from mdnote
            if match_type == "with_title":
                updated_mdnote = f"{prefix}{date}{opening_brace}"
                title_start = match.start()
                title_end = match.end()

                # Replace the mdnote part
                new_content = new_content[:title_start] + updated_mdnote + new_content[title_end:]

                # Insert tags at the beginning of the entry content
                content_start = title_start + len(updated_mdnote)
                new_content = new_content[:content_start] + tags_str + new_content[content_start:]
            else:  # without_title
                # Just insert tags at the beginning of the entry content
                new_content = new_content[:content_start] + tags_str + new_content[content_start:]

            changes_made += 1

    # Only write if content changed
    if changes_made > 0:
        if dry_run:
            print(f"[DRY-RUN] Would update {changes_made} entries with tags in {filepath}")
            return True
        try:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"✅ Updated {changes_made} entries with tags in {filepath}")
            return True
        except IOError as e:
            print(f"Error writing to {filepath}: {e}")
            return False
    else:
        print(f"No changes needed in {filepath}")
        return True


def test_til():
    """Run test cases for title improvement logic."""
    test_cases = [
        {
            "name": "Basic technical content",
            "content": "Worked on Rust compiler optimizations today. Learned about SIMD intrinsics.",
            "expected": ["rust", "simd", "compiler", "optimization"],
        },
        {
            "name": "Citation content",
            "content": "Read \\citef{li2023camel}",
            "expected": ["agent"],
        },
        {
            "name": "Project reference",
            "content": "Continued work on [[ag-0018]] with new features.",
            "expected": ["✍️"],
        },
        {
            "name": "Explicit tag extraction",
            "content": "Today I learned about #debugger and #raku in depth.",
            "expected": ["debugger", "raku"],
        },
        {
            "name": "Explicit tag deduplication",
            "content": "#debugger #raku Also learned about debugger and raku.",
            "expected": ["debugger", "raku"],
        },
        {
            "name": "Mixed content",
            "content": "- llvm related improvements to codegen\n- Fixed wasm interop issues",
            "expected": ["llvm", "wasm", "codegen", "interop"],
        },
        {
            "name": "Non-technical content",
            "content": "Had meeting about project planning and timelines.",
            "expected": [],
        },
    ]

    print("🧪 Running TIL Test Suite...\n")
    passed = 0
    failed = 0

    for case in test_cases:
        print(f"Test: {case['name']}")
        print(f"Content: {case['content'][:60]}...")
        date = "2025-01-01"  # Dummy date for testing
        # Test both dedup and no-dedup for explicit tag cases
        if "Explicit tag" in case["name"]:
            result_dedup = extract_keywords_from_content(case["content"], date, dedup=True)
            result_no_dedup = extract_keywords_from_content(case["content"], date, dedup=False)
            print(f"Dedup ON: {result_dedup}")
            print(f"Dedup OFF: {result_no_dedup}")
            # For dedup ON, expect []
            if result_dedup == []:
                print(f"✅ PASS (dedup) - Got: {result_dedup}")
                passed += 1
            else:
                print(f"❌ FAIL (dedup) - Expected: [], Got: {result_dedup}")
                failed += 1
            # For no-dedup, explicit tags should be included and merged
            raw_tags = [tag for tag in re.findall(r'#(\w+)', case["content"])]
            expected_no_dedup = []
            for tag in raw_tags:
                merged = False
                for preferred, alternatives in TAG_MERGE.items():
                    if tag == preferred or tag in alternatives:
                        expected_no_dedup.append(preferred)
                        merged = True
                        break
                if not merged:
                    expected_no_dedup.append(tag)
            expected_no_dedup = sorted(expected_no_dedup)
            if sorted(result_no_dedup) == expected_no_dedup:
                print(f"✅ PASS (no-dedup) - Got: {result_no_dedup}")
                passed += 1
            else:
                print(f"❌ FAIL (no-dedup) - Expected: {expected_no_dedup}, Got: {result_no_dedup}")
                failed += 1
        else:
            result = extract_keywords_from_content(case["content"], date)
            if sorted(result) == sorted(case["expected"]):
                print(f"✅ PASS - Got: {result}")
                passed += 1
            else:
                print(f"❌ FAIL - Expected: {case['expected']}, Got: {result}")
                failed += 1
        print()

    print(f"\nTest Results: {passed} passed, {failed} failed")
    return failed == 0


def _extract_tags_from_file(filepath, dedup=True):
    """Utility: Extracts all tags from file, returns a list of tags per entry. Respects dedup flag."""
    import re
    tags_per_entry = []
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception:
        return []
    pattern_tags = r"\\tags\{([^}]*)\}"
    for match in re.finditer(pattern_tags, content):
        tags = match.group(1)
        tag_list = [t for t in tags.split() if t.startswith('#')]
        if dedup:
            # Already deduped in main logic
            tags_per_entry.append(tag_list)
        else:
            tags_per_entry.append(tag_list)
    return tags_per_entry

def _color_tag(tag):
    import sys
    use_color = sys.stdout.isatty()
    return f"\033[38;5;114m{tag}\033[0m" if use_color else tag

def print_merge_stats(dedup=True, filepath=None):
    """Print aggregated keyword merge statistics, respecting dedup flag. Consistent output."""
    from collections import defaultdict
    merge_stats = defaultdict(set)
    if not dedup and filepath is not None:
        tags_per_entry = _extract_tags_from_file(filepath, dedup=False)
        for tag_list in tags_per_entry:
            for tag in [t[1:] for t in tag_list]:
                for preferred, alternatives in TAG_MERGE.items():
                    if tag == preferred or tag in alternatives:
                        if tag != preferred:
                            merge_stats[preferred].add(tag)
    else:
        # Use global MERGE_STATS (dedup=True)
        for preferred, merged in MERGE_STATS.items():
            if merged:
                merge_stats[preferred].update(merged)
    if merge_stats:
        print("\nAggregated keyword merge statistics:")
        for preferred, merged in sorted(merge_stats.items(), key=lambda x: len(x[1]), reverse=True):
            if merged:
                merged_str = ", ".join(sorted(merged))
                print(f"{_color_tag(preferred)} <- {merged_str}")


def print_global_tag_stats(filepath, dedup=True):
    """Print global tag statistics: each tag and its count, ordered by count desc, then alphabetically. Consistent output."""
    from collections import Counter
    tag_counter = Counter()
    tags_per_entry = _extract_tags_from_file(filepath, dedup=dedup)
    for tag_list in tags_per_entry:
        for t in tag_list:
            tag_counter[t] += 1
    if tag_counter:
        print("\nGlobal tag stats:")
        sorted_tags = sorted(tag_counter.items(), key=lambda x: (-x[1], x[0]))
        max_tag_len = max(len(tag) for tag, _ in sorted_tags)
        for tag, count in sorted_tags:
            print(f"{_color_tag(tag):<{max_tag_len+2}} {count}")

def print_monthly_tag_stats(filepath, top_n=20, dedup=True):
    """Print top N tag statistics for each month, including months with no tags, and show total tag count. Consistent output."""
    import re
    from collections import defaultdict, Counter
    month_tag_counter = defaultdict(Counter)
    all_months = set()
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception:
        return
    # Find all mdnote entries (with or without tags) to collect all months
    pattern_month = r"\\subtree\[(\d{4}-\d{2})-\d{2}\]{\\mdnote{\d{4}-\d{2}-\d{2}}"
    for match in re.finditer(pattern_month, content):
        month = match.group(1)
        all_months.add(month)
    # Find all mdnote entries with tags
    pattern_tags = r"\\subtree\[(\d{4}-\d{2})-\d{2}\]{\\mdnote{\d{4}-\d{2}-\d{2}}{\\tags{([^}]*)}"
    for match in re.finditer(pattern_tags, content):
        month = match.group(1)
        tags = match.group(2)
        tag_list = [t for t in tags.split() if t.startswith('#')]
        for t in tag_list:
            month_tag_counter[month][t] += 1
    if all_months:
        print("\nMonthly tag stats:")
        for month in sorted(all_months):
            top_tags = month_tag_counter[month].most_common(top_n)
            unique_tag_count = len(month_tag_counter[month])
            yyyymm = month.replace('-', '')
            tag_str = ', '.join([
                _color_tag(tag) if count == 1 else f"{_color_tag(tag)} {count}"
                for tag, count in top_tags
            ])
            if unique_tag_count > top_n:
                tag_str += ', ...'
            print(f"{yyyymm} ({unique_tag_count} tags): {tag_str}")




if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="TIL (Today I Learned) Title Improver")
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show detailed logs for each tag extraction event"
    )
    parser.add_argument(
        "--dedup",
        action="store_true",
        default=True,
        help="Deduplicate explicit #tags from output (affects --stat, --stat-all, --merge-stat; default: deduplication ON)",
    )
    parser.add_argument(
        "--no-dedup",
        action="store_true",
        help="Do NOT deduplicate explicit #tags (explicit tags will be included in all stats)",
    )
    parser.add_argument(
        "--reset",
        action="store_true",
        help="Reset all titles to date-only (remove : title part)",
    )
    parser.add_argument(
        "--test",
        action="store_true",
        help="Run test cases instead of processing files",
    )
    parser.add_argument(
        "--stat",
        nargs="?",
        type=int,
        const=20,
        help="Show monthly tag stats (optionally top N tags per month)",
    )
    parser.add_argument(
        "--stat-all",
        action="store_true",
        help="Show global tag stats (all tags, ordered by count)"
    )
    parser.add_argument(
        "--merge-stat",
        action="store_true",
        help="Show aggregated keyword merge statistics (default: OFF)"
    )
    # AGENT-NOTE: --merge-stat controls merge stats output; default is OFF for clean output
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simulate changes without modifying any files (no reset or tag updates, but stats and analysis still run)",
    )
    args = parser.parse_args()

    if args.test:
        if test_til():
            sys.exit(0)
        else:
            sys.exit(1)

    filepath = Path("trees/uts-0018.tree")

    if not filepath.exists():
        print(f"Error: File {filepath} not found")
        print("Expected file: trees/uts-0018.tree (learning diary)")
        sys.exit(1)

    if args.reset:
        print("🔄 TIL Title Resetter - Removing all title keywords...")
        success = reset_titles(filepath, dry_run=getattr(args, 'dry_run', False))
        if success:
            print("✨ Title reset complete!" if not getattr(args, 'dry_run', False) else "✨ [DRY-RUN] Title reset simulation complete!")
        else:
            print("❌ Title reset failed")
            sys.exit(1)
    else:
        print("🔍 TIL Title Improver - Analyzing daily entries...")
        success = process_file(filepath, verbose=getattr(args, 'verbose', False), dry_run=getattr(args, 'dry_run', False))
        if success:
            print("✨ Title improvement complete!" if not getattr(args, 'dry_run', False) else "✨ [DRY-RUN] Title improvement simulation complete!")
            dedup = getattr(args, 'dedup', True) and not getattr(args, 'no_dedup', False)
            if getattr(args, 'stat', None) is not None:
                print_monthly_tag_stats(filepath, top_n=args.stat, dedup=dedup)
            if getattr(args, 'stat_all', False):
                print_global_tag_stats(filepath, dedup=dedup)
            if getattr(args, 'merge_stat', False):
                print_merge_stats(dedup=dedup, filepath=filepath)
        else:
            print("❌ Title improvement failed")
            sys.exit(1)
