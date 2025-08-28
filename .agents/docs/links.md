# Link Pre-processing Preferences

This document captures the unified approach for preprocessing links across different sources (TIL entries, GitHub stars, Linkwarden imports) based on patterns observed in `til.py`, `stars.py`, and `linkwarden_import.py`.

## Core Principles

### 1. Link Enrichment Strategy

All scripts must enhance existing content rather than duplicate:

- **Enrich existing URLs incrementally**: Merge new information with existing entries, see *Link Enrichment Logic* below
- **Preserve earliest timestamps**: publish time > received time > starred time  
- **Deterministic ordering**: Sort entries per *Date-Based Organization* below

### 2. Smart Content Enhancement

Transform raw links into meaningful, searchable content:

- **Title generation**: Create descriptive titles from URLs when missing
- **Context preservation**: Maintain source information (HN, Lobsters, etc.)
- **Keyword extraction** (optional): Automatically tag content with technical keywords

## URL Processing Patterns

### Normalization Strategy

```python
def normalize_url(url):
    # Only normalize scheme, hostname case, and trailing slashes
    # Preserve query strings and fragments for content identification
    parsed = urllib.parse.urlparse(url)
    return urllib.parse.urlunparse(ParseResult(
        scheme=parsed.scheme.lower(),
        netloc=parsed.netloc.lower(), 
        path=parsed.path.rstrip("/") or "/",
        params=parsed.params,
        query=parsed.query,      # Preserve as-is
        fragment=parsed.fragment # Preserve as-is
    ))
```

### Link Enrichment Logic

- Extract existing URLs from target files using regex patterns
- Normalize both existing and new URLs for comparison
- **Complement existing entries** rather than skip duplicates:
  - **Timestamps**: Preserve earliest (publish time > received time > starred time)
  - **Titles**: Preserve existing, warn if different from new source
  - **Tags/Discussions/Notes/Related links/Quotes**: Deduplicate and merge (append unique items)
  - **Enrichment failures**: Skip entry, retry later (idempotent design allows this)
- Track enrichment operations in statistics

### Two-Phase Import Workflow

For safe handling of conflicting data:

1. **Phase 1 - Discovery**: Run import without force flags
   - Preserves existing data following conflict resolution rules
   - Warns about conflicts (titles, descriptions, etc.)
   - Shows what would be updated vs what conflicts exist

2. **Phase 2 - Force Update**: After human review, selectively force updates
   - Use `--force title` to override title conflicts
   - Use `--force description` to override description conflicts  
   - Can combine multiple force flags: `--force title --force description`

**Example workflow:**
```bash
# Phase 1: Discover conflicts
./rss2linkwarden.py data.csv | ./linkwarden_import.py --days 7

# Review warnings, then force specific updates
./rss2linkwarden.py data.csv | ./linkwarden_import.py --days 7 --force title
```

This ensures human oversight for potentially destructive updates while maintaining automation for safe enrichment operations.

## Title Enhancement

### Automatic Title Generation

When titles are missing or inadequate:
```python
def generate_title_from_url(url):
    # Mastodon-like: https://mathstodon.xyz/@tao/114603605315214772
    if mastodon_pattern.match(url):
        return f"{username}'s post on {domain}"
    
    # Default: extract domain
    return f"Post on {domain}"
```

### Title Cleaning

- Replace newlines with spaces
- Collapse multiple whitespace into single spaces

## Keyword Extraction System

### Tagging

Simple tag extraction supporting:

- **Exact match tags**: Direct string matching (`"rust"`, `"wasm"`)
- **Pattern tags**: Regex-based extraction for complex patterns
- **Merge rules**: Consolidate similar tags (`"formalization" → "formal"`)

### Technical Tag Category Examples

- **Languages**: rust, zig, elixir, lean, haskell, ocaml, etc.
- **AI/ML**: claude, dspy, qwen, embedding, prompt, agent
- **Systems**: simd, wasm, gpu, ebpf, docker, kubernetes
- **Formal methods**: formal, verification, smt, sat, proof
- **Infrastructure**: build, optimization, benchmark, security

### Context-Sensitive Processing

- **Git detection**: Only tag as "git" if actual git commands/concepts present
- **Project references**: Extract prefixes from `[[ag-0018]]` style wiki links
- **Citation keywords**: Extract from bibliography titles via `\citef{}` references

## Source Attribution

### Discussion Link Handling

Show source links strategically:
- **HN present**: Always show discussion links (HN + others)
- **Lobsters only**: Hide discussion links (reduce noise)
- **Multiple sources**: Show all when `--show-all-sources` enabled

### Format Patterns

```markdown
- [Title](url) ([on HN](hn-url)) ([on Lobsters](lobsters-url))
```

## Date-Based Organization

### Chronological Grouping

- Group entries by date (YYYY-MM-DD format)
- Sort dates in reverse chronological order (newest first)
- Preserve existing link order, and append new links in the same date at the end of the group for the date

### Time Filtering

- Support `--days N` parameter for recent entries only
- Use `dateArrived` or `datePublished` timestamps
- Default to last 7 days for focused processing

## Output Formatting

### Forester Integration

When the output format is markdown embedded in forester markup, generate valid Forester syntax (LaTeX-like):

```
\subtree[2025-01-15]{\mdnote{2025-01-15}{
\tags{#rust #wasm #optimization}
- [Rust WASM optimization techniques](https://example.com/article)
}}
```

and handle special format details:

- Use `\verb>>>|text>>>` for URLs/titles containing `%` or other special chars
- Proper brace matching for nested Forester structures
- Escape sequences for LaTeX compatibility

## Error Handling & Resilience

### Graceful Degradation

- Continue processing if individual entries fail
- Provide meaningful error messages with context
- Track statistics for success/failure rates

### Rate Limiting

- Batch processing with configurable delays
- Smart rate limiting (only for resource-intensive operations, e.g. archiving the link content)
- Progress reporting for long-running operations

## Statistics & Monitoring

### Processing Metrics

Track and report:
- Total entries processed
- Duplicates skipped
- New entries created/updated
- Source distribution (HN, Lobsters, etc.)

### Tag Analytics

- Monthly tag statistics
- Global tag frequency
- Merge operation tracking
- Trend analysis capabilities

## Configuration Management

### Environment Variables

- API tokens and endpoints
- Rate limiting parameters
- Default file paths

### Command Line Interface

Consistent parameter patterns:

- `--dry-run`: Preview without changes
- `--days N`: Time-based filtering
- `--verbose`: Detailed logging
- `--no-dedup`: Disable deduplication

## Integration Points

### File Dependencies

- link deduplication
    - `trees/uts-0018.tree`: Main learning diary
    - `trees/uts-016E.tree`: Link collection
- `tex/*.bib`: Bibliography for citation keywords

### External Services

- **RSS feeds**: Content aggregation
- **Raindrop/Linkwarden API**: Link management and archival 

This unified approach ensures consistent, high-quality link processing across all sources while maintaining the technical focus and organizational structure that supports effective knowledge management.
