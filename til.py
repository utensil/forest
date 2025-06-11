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

import re
import sys
from pathlib import Path
import glob

def load_bib_titles():
    """Load all bib titles from tex/*.bib files for citation matching."""
    bib_titles = {}
    
    for bib_file in glob.glob("tex/*.bib"):
        try:
            with open(bib_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Extract bib entries with cite keys and titles
            # Pattern matches: @type{key, ... title={...}, ...}
            pattern = r'@\w+\{\s*([^,]+),.*?title\s*=\s*\{([^}]+)\}'
            matches = re.findall(pattern, content, re.DOTALL | re.IGNORECASE)
            
            for cite_key, title in matches:
                cite_key = cite_key.strip()
                title = title.strip()
                # Clean up title - remove LaTeX commands and normalize
                title = re.sub(r'\\[a-zA-Z]+\{([^}]*)\}', r'\1', title)  # Remove LaTeX commands
                title = re.sub(r'[{}]', '', title)  # Remove remaining braces
                title = re.sub(r'\s+', ' ', title).strip()  # Normalize whitespace
                bib_titles[cite_key] = title
                
        except Exception as e:
            print(f"Warning: Could not parse {bib_file}: {e}")
            
    return bib_titles

def extract_keywords_from_content(content):
    """Extract meaningful technical keywords from daily entry content."""
    
    # Load bib titles for citation keyword extraction
    bib_titles = load_bib_titles()
    
    # Priority tech keywords - specific technologies, tools, languages
    priority_keywords = {
        # Programming languages
        'rust', 'zig', 'elixir', 'clojure', 'js', 'typescript', 'python', 'cpp', 'go', 'lean', 'apl',
        'racket', 'rhombus', 'effekt', 'slang', 'impala', 'haskell', 'ocaml',
        # AI/ML specific tools
        'claude', 'dspy', 'textgrad', 'zenbase', 'simba', 'grpo', 'grok', 'qwen', 'embedding', 'prompt',
        'chatgpt', 'gemini', 'anthropic', 'openai', 'reasoning', 'chain-of-thought', 'fine-tuning', 'rlhf',
        'neural', 'transformer', 'abliteration', 'codegen', 'assistant', 'workflow',
        # Systems/Performance specific
        'simd', 'wasm', 'webgpu', 'gpu', 'ebpf', 'optimization', 'rustc', 'clang', 'gcc', 'llvm', 'pulp', 'faer',
        'speedup', 'async', 'runtime', 'performance',
        # Math/Science
        'galgebra', 'geometric', 'clifford', 'tla', 'category', 'theory', 'gradient', 'spiral',
        'multivector', 'versor', 'lipschitzian',
        # Graphics/Rendering
        'shader', 'raymarching', 'rendering', 'webgl', 'fluid', 'simulation', 'siggraph', 'animation',
        'schwarzschild', 'visualization', 'compute',
        # Infrastructure/Tools specific
        'kubernetes', 'docker', 'containerd', 'backrest', 'restic', 'talos', 'metallb', 'unbound',
        'headscale', 'tailscale', 'harbor', 'salt', 'ansible', 'lima', 'nsjail', 'haproxy', 'healthchecks',
        'veracrypt', 'makefile', 'ssh', 'apt', 'homelab', 'infrastructure',
        # Databases/Analytics
        'datafusion', 'duckdb', 'sqlite', 'postgres', 'apache', 'arrow', 'parquet', 'litestream',
        # Security/Testing specific
        'fuzzing', 'security', 'vulnerability', 'formal', 'methods', 'verification', 'encryption', 'backup',
        # Fediverse/Social
        'fediverse', 'mastodon', 'activitypub', 'lemmy', 'pixelfed', 'bookwyrm', 'peertube', 'pleroma',
        # Development tools
        'git', 'jujutsu', 'compiler', 'zigar', 'perses', 'benchmark', 'profiling', 'agents', 'interop',
        'biome', 'aider', 'htmx', 'neovim', 'zed', 'tmux', 'worktree',
        # File/Media tools
        'exif', 'id3', 'renaming', 'bulk', 'metadata', 'typst',
        # Specs/Protocols
        'vulkan', 'opengl', 'mcp', 'nlweb', 'json', 'yaml', 'toml', 'xml', 'csv', 'avro',
        # Hardware/Architecture
        'x86', 'arm', 'aarch64', 'sandboxing',
        # Academic/Research domains
        'research', 'theory', 'citation', 'proof', 'theorem', 'lemma',
        'gauge', 'quantum', 'physics', 'astrophysical', 'dirac', 'philosophical',
        # Keywords from bibliography titles
        'matrix', 'geometric', 'levenberg', 'marquardt', 'knot', 'origami', 'weyl', 'hamiltonian',
        'normalization', 'neural', 'translation', 'attention', 'transformer', 'lstm', 'sequence',
        'tensor', 'alignment',
        # Tools/Libraries broader
        'symbolica', 'bevy', 'knuckledragger', 'z3', 'bpf', 'atproto', 'ghostty',
        # Personal/Life activities
        'busy', 'office', 'plans', 'skiing', 'paragliding',
        # Content/Media
        'zen', 'motorcycle', 'maintenance', 'values', 'wang', 'guowei'
    }
    
    # Extract keywords from content
    content_lower = content.lower()
    found_keywords = []
    
    # Look for priority keywords with context sensitivity
    for keyword in sorted(priority_keywords):  # Sort for deterministic order
        if keyword in content_lower:
            # Handle special cases
            if keyword == 'cpp' and 'c++' in content_lower:
                found_keywords.append('c++')
                continue
            if keyword == 'js' and 'javascript' in content_lower:
                found_keywords.append('javascript')
                continue
            if keyword == 'git':
                # Only include 'git' if it's about Git the tool, not just GitHub URLs
                if any(git_term in content_lower for git_term in [
                    'git clone', 'git commit', 'git push', 'git pull', 'git branch',
                    'git merge', 'git rebase', 'git log', 'git status', 'git add',
                    'git-remote', 'git repo', 'git workflow', 'version control',
                    'git history', 'git config', 'git diff', 'git checkout'
                ]):
                    found_keywords.append(keyword)
                continue
                
            found_keywords.append(keyword)
    
    # Look for specific project/tool names mentioned
    project_patterns = [
        r'\b([a-z]+(?:db|sql|query))\b',  # Database tools
        r'\b(jepsen|tigerbeetle|cloudflare)\b',  # Specific projects
        r'\b(mastodon|lemmy|pixelfed|bookwyrm|peertube|pleroma)\b',  # Fediverse
        r'\b(backrest|restic|talos|metallb|unbound|headscale|harbor)\b',  # Infrastructure
        r'\b(zigar|perses|pulp|faer|galgebra)\b',  # Specialized tools
        r'\b(datafusion|duckdb|apache|arrow|parquet)\b',  # Analytics
        r'\[\[(uts|ag|tt|spin|hopf)-[0-9a-z]+\]\]',  # Project tree references
    ]
    
    for pattern in project_patterns:
        matches = re.findall(pattern, content_lower)
        for match in sorted(matches):  # Sort for deterministic order
            if isinstance(match, tuple):
                # Handle patterns that return tuples (like tree references)
                for submatch in match:
                    if submatch and submatch not in found_keywords:
                        # Map uts to notes, keep other project prefixes as keywords
                        if submatch == 'uts':
                            found_keywords.append('notes')
                        else:
                            found_keywords.append(submatch)
            else:
                if match and match not in found_keywords:
                    found_keywords.append(match)
    
    # Process citations - extract keywords from bib titles instead of cite keys
    citation_pattern = r'\\citef\{([^}]+)\}'
    citations = re.findall(citation_pattern, content_lower)
    for cite_key in citations:
        cite_key = cite_key.strip()
        if cite_key in bib_titles:
            title = bib_titles[cite_key].lower()
            # Extract keywords from the title using the same priority keywords
            for keyword in sorted(priority_keywords):
                if keyword in title and keyword not in found_keywords:
                    found_keywords.append(keyword)
    
    # Remove duplicates and sort for consistent output
    unique_keywords = []
    seen = set()
    for kw in sorted(found_keywords):  # Sort for deterministic order
        if kw not in seen:
            unique_keywords.append(kw)
            seen.add(kw)
    
    # Limit to top 6 keywords to keep titles concise
    return unique_keywords[:6]

def improve_title(date, content):
    """Generate improved title based on content analysis."""
    keywords = extract_keywords_from_content(content)
    
    if not keywords:
        # Fallback for entries with no technical keywords
        return f"{date}: misc"
    
    # Join keywords with commas
    keyword_str = ', '.join(keywords)
    return f"{date}: {keyword_str}"

def find_matching_brace(text, start_pos):
    """Find the position of the matching closing brace, handling nested braces."""
    brace_count = 0
    pos = start_pos
    
    while pos < len(text):
        if text[pos] == '{':
            brace_count += 1
        elif text[pos] == '}':
            brace_count -= 1
            if brace_count == 0:
                return pos
        pos += 1
    
    return -1  # No matching brace found

def process_file(filepath):
    """Process the tree file and improve all daily entry titles."""
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: File {filepath} not found")
        return False
    except IOError as e:
        print(f"Error reading {filepath}: {e}")
        return False
    
    # Pattern to match the start of mdnote entries
    pattern = r'(\\subtree\[[^\]]+\]\{\\mdnote\{)([^:]+): ([^}]+)\}(\{)'
    
    # Find all matches and process them in reverse order to avoid position shifts
    matches = list(re.finditer(pattern, content, flags=re.DOTALL))
    if not matches:
        print(f"No daily entries found in {filepath}")
        return True
    
    print(f"Processing {len(matches)} daily entries...")
    
    # Process matches in reverse order to maintain correct positions
    new_content = content
    changes_made = 0
    
    for match in reversed(matches):
        prefix = match.group(1)  # \subtree[date]{\mdnote{
        date = match.group(2)    # date part
        old_title = match.group(3)  # old title part
        opening_brace = match.group(4)  # opening brace {
        
        # Find the matching closing brace for the content
        content_start = match.end()
        content_end = find_matching_brace(new_content, content_start - 1)  # -1 because we want to include the opening brace
        
        if content_end == -1:
            print(f"Warning: Could not find matching brace for entry {date}")
            continue
        
        # Extract the content between braces (excluding the braces themselves)
        inner_content = new_content[content_start:content_end-1]  # -1 to exclude the closing brace
        
        # Generate new title
        new_title = improve_title(date, inner_content)
        
        # Only update if title changed
        if f"{date}: {old_title}" != new_title:
            # Replace the title part only
            title_start = match.start(2)
            title_end = match.end(3)
            new_content = new_content[:title_start] + new_title + new_content[title_end:]
            changes_made += 1
    
    # Only write if content changed
    if changes_made > 0:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"✅ Updated {changes_made} titles in {filepath}")
            return True
        except IOError as e:
            print(f"Error writing to {filepath}: {e}")
            return False
    else:
        print(f"No title changes needed in {filepath}")
        return True

if __name__ == "__main__":
    filepath = Path("trees/uts-0018.tree")
    
    if not filepath.exists():
        print(f"Error: File {filepath} not found")
        print("Expected file: trees/uts-0018.tree (learning diary)")
        sys.exit(1)
    
    print("🔍 TIL Title Improver - Analyzing daily entries...")
    success = process_file(filepath)
    
    if success:
        print("✨ Title improvement complete!")
    else:
        print("❌ Title improvement failed")
        sys.exit(1)
