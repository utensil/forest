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


def extract_keywords_from_content(content, date):
    """Extract meaningful technical keywords from daily entry content."""

    # Load bib titles for citation keyword extraction
    bib_titles = load_bib_titles()

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

    # Priority tech keywords - specific technologies, tools, languages
    priority_keywords = {
        # Programming languages
        "rust",
        "zig",
        "elixir",
        "lean",
        "apl",
        "haskell",
        "ocaml",
        "clojure",
        "racket",
        # AI/ML specific tools
        "claude",
        "dspy",
        "qwen",
        "embedding",
        "prompt",
        "agent",
        "textgrad",
        "zenbase",
        # Systems/Performance specific
        "simd",
        "wasm",
        "gpu",
        "optimization",
        "performance",
        "ebpf",
        "llvm",
        # Math/Science
        "galgebra",
        "clifford",
        "theory",
        "tla",
        "category",
        "gradient",
        # Graphics/Rendering
        "render",
        "shader",
        "visualization",
        "webgl",
        "raymarching",
        "game",
        # Infrastructure/Tools specific
        "docker",
        "talos",
        "unbound",
        "harbor",
        # Databases/Analytics
        "sqlite",
        "datafusion",
        "duckdb",
        # Security/Testing specific
        "security",
        "formal",
        "verification",
        "smt",
        "sat",
        "fuzzing",
        # Fediverse/Social
        "fediverse",
        "mastodon",
        "lemmy",
        # Development tools
        "git",
        "compiler",
        "benchmark",
        "neovim",
        "jujutsu",
        "biome",
        # File/Media tools
        "typst",
        "exif",
        "id3",
        # Specs/Protocols
        "vulkan",
        "json",
        "yaml",
        "toml",
        # Hardware/Architecture
        "arm",
        "x86",
        # Academic/Research domains
        "proof",
        "quantum",
        "physics",
        "citation",
        "lemma",
        # Tools/Libraries broader
        "bevy",
        "z3",
        "symbolica",
        # Authoring
        "wrote",
        "finish",
        "start on",
        "progress on",
    }

    # Extract keywords from content
    content_lower = content.lower()
    found_keywords = []

    # Project patterns to match specific tools/projects
    project_patterns = [
        r"\b([a-z][a-z0-9]+(?:db|sql|query))\b",  # Database tools
        r"\b(jepsen|tigerbeetle|cloudflare)\b",  # Specific projects
        r"\b(mastodon|lemmy|pixelfed|bookwyrm|peertube|pleroma)\b",  # Fediverse
        r"\b(backrest|restic|talos|metallb|unbound|headscale|harbor)\b",  # Infrastructure
        r"\b(zigar|perses|pulp|faer|galgebra)\b",  # Specialized tools
        r"\b(datafusion|duckdb|apache|arrow|parquet)\b",  # Analytics
        r"\[\[(uts|ag|tt|spin|hopf)-[0-9a-z]+\]\]",  # Project tree references with prefix
        r"\[\[(uts|ag|tt|spin|hopf)-[0-9]+\]\]",  # Project tree references without prefix
    ]

    # First look for project/tool names (highest priority)
    for pattern in project_patterns:
        matches = re.findall(pattern, content_lower)
        for match in sorted(matches):  # Sort for deterministic order
            if isinstance(match, tuple):
                for submatch in match:
                    if submatch and submatch not in EXCLUDE_WORDS:
                        found_keywords.append(submatch)
            else:
                if match and match not in EXCLUDE_WORDS:
                    found_keywords.append(match)

    # Then look for priority keywords with context sensitivity
    for keyword in sorted(priority_keywords):  # Sort alphabetically only
        if keyword in content_lower:
            # Handle special cases
            if keyword == "cpp" and "c++" in content_lower:
                found_keywords.append("c++")
                continue
            if keyword == "js" and "javascript" in content_lower:
                found_keywords.append("javascript")
                continue
            if keyword == "git":
                # Only include 'git' if it's about Git the tool, not just GitHub URLs
                if any(
                    git_term in content_lower
                    for git_term in [
                        "git clone",
                        "git commit",
                        "git push",
                        "git pull",
                        "git branch",
                        "git merge",
                        "git rebase",
                        "git log",
                        "git status",
                        "git add",
                        "git-remote",
                        "git repo",
                        "git workflow",
                        "version control",
                        "git history",
                        "git config",
                        "git diff",
                        "git checkout",
                    ]
                ):
                    found_keywords.append(keyword)
                continue

            found_keywords.append(keyword)

    # Improved pattern with better word boundaries and validation
    topic_related_matches = re.findall(
        r"^\s*- (?:\[([^\]]+)\]|((?:\b[a-z][a-z0-9]*\b\s*)+))\s+related\b",
        content_lower,
        re.MULTILINE,
    )
    logger.debug(f"Found {len(topic_related_matches)} topic-related patterns")
    for match in sorted(topic_related_matches):  # Sort for deterministic order
        topic = match[0] or match[1]  # Use either bracketed or non-bracketed match
        logger.debug(f"Processing topic-related: {topic}")
        if topic:
            # Convert multi-word topics into hyphenated keywords
            topic = topic.strip().lower()
            if ' ' in topic:
                # Replace spaces with hyphens for multi-word topics
                hyphenated = '-'.join(topic.split())
                if (
                    hyphenated
                    and hyphenated not in EXCLUDE_WORDS
                    and hyphenated not in found_keywords
                    and re.fullmatch(r"[a-z][a-z0-9-]*", hyphenated)
                ):
                    found_keywords.append(hyphenated)
            else:
                # Handle single word topics normally
                if (
                    topic
                    and topic not in EXCLUDE_WORDS
                    and topic not in found_keywords
                    and re.fullmatch(r"[a-z][a-z0-9-]*", topic)
                ):
                    found_keywords.append(topic)

    # Process citations - extract keywords from bib titles instead of cite keys
    citation_pattern = r"\\citef\{([^}]+)\}"
    citations = re.findall(citation_pattern, content_lower)
    for cite_key in citations:
        cite_key = cite_key.strip()
        if cite_key in bib_titles:
            title = bib_titles[cite_key].lower()
            # Extract keywords from the title using the same priority keywords
            for keyword in sorted(priority_keywords):
                if keyword in title and keyword not in found_keywords:
                    found_keywords.append(keyword)

    # Keyword mappings to merge semantically similar terms
    # Keys are the preferred terms, values are sets of alternatives
    KEYWORD_MAPPINGS = {
        "_merge_stats": {},  # Track merge stats
        # Authoring/work tracking
        "✍️": {"wrote", "finish", "start on", "progress on", "uts"},
        # "cg": {
        #     "render",
        #     "shader",
        #     "webgl",
        #     "raymarching",
        # },
        # but lean, z3, tla should get their own keywords due to their importance to me
        "formal": {"formalization", "verification", "smt", "sat"},
        "agent": {"ai"},
    }

    # Merge similar keywords according to mappings
    merged_keywords = set()
    for kw in found_keywords:
        found = False
        for preferred, alternatives in KEYWORD_MAPPINGS.items():
            if preferred == "_merge_stats":
                continue
            if kw == preferred or kw in alternatives:
                merged_keywords.add(preferred)
                found = True
                # Track merge stats (only if kw is different from preferred)
                if kw != preferred:
                    if preferred not in KEYWORD_MAPPINGS["_merge_stats"]:
                        KEYWORD_MAPPINGS["_merge_stats"][preferred] = set()
                    KEYWORD_MAPPINGS["_merge_stats"][preferred].add(kw)
                break
        if not found:
            merged_keywords.add(kw)

    # Track merge stats if enabled
    if "_merge_stats" in KEYWORD_MAPPINGS:
        for preferred, merged in KEYWORD_MAPPINGS.get("_merge_stats", {}).items():
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


def improve_title(date, content):
    """Generate improved title based on content analysis."""
    keywords = extract_keywords_from_content(content, date)

    if not keywords:
        # Fallback for entries with no technical keywords
        return date, ["misc"]

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


def reset_titles(filepath):
    """Reset all daily entry titles to just dates (remove : title part) and remove tags."""

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


def process_file(filepath):
    """Process the tree file and improve all daily entry titles."""

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
        new_date, keywords = improve_title(date, inner_content)

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
            "expected": ["ag"],
        },
        {
            "name": "Explicit topic",
            "content": "- debugger related\n- Raku related",
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


def print_merge_stats():
    """Print aggregated keyword merge statistics."""
    if MERGE_STATS:
        print("\nAggregated keyword merge statistics:")
        for preferred, merged in sorted(
            MERGE_STATS.items(), key=lambda x: len(x[1]), reverse=True
        ):
            if merged:
                merged_str = ", ".join(sorted(merged))
                print(f"{preferred} <- {merged_str}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="TIL (Today I Learned) Title Improver")
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
        success = reset_titles(filepath)
        if success:
            print("✨ Title reset complete!")
        else:
            print("❌ Title reset failed")
            sys.exit(1)
    else:
        print("🔍 TIL Title Improver - Analyzing daily entries...")
        success = process_file(filepath)
        if success:
            print("✨ Title improvement complete!")
            print_merge_stats()
        else:
            print("❌ Title improvement failed")
            sys.exit(1)
