---
id: task-0015
title: Create rss2linkwarden.py script
status: Done
assignee:
  - '@agent'
created_date: '2025-08-28'
updated_date: '2025-08-28'
labels: []
dependencies: []
---

## Description

Convert CSV export from RSS reader to Linkwarden import format, following link processing guidelines

## Acceptance Criteria

- [x] Script processes CSV input correctly
- [x] Maps excerpt to textContent field
- [x] Maps note and highlights to description with proper formatting
- [x] Processes note line-by-line to extract and import additional links
- [x] Creates reference links with appropriate tags (re/hn re/lb re/rd)
- [x] Maps folder to Linkwarden collection
- [x] Enhances HN/Lobsters URL format like existing script
- [x] Handles errors gracefully
- [x] Includes proper documentation
## Implementation Plan

1. Analyze CSV input format and Linkwarden API requirements
2. Research Linkwarden import format from existing linkwarden_import.py
3. Create minimal CSV-to-Linkwarden conversion script following links.md guidelines
4. Implement URL normalization and link enrichment patterns
5. Add proper error handling and validation
6. Test with sample CSV data
7. Document usage and integration


## Implementation Notes

Created rss2linkwarden.py script that converts RSS CSV exports to Linkwarden format.

**Approach Taken:**
- Pipeline design: CSV → JSON lines → linkwarden_import.py for robust import
- Rich data mapping following OpenAPI spec and user requirements
- Line-by-line note processing to extract reference links

**Features Implemented:**
- Maps excerpt → textContent, note+highlights → description with markdown formatting
- Extracts HN/Lobsters/Reddit URLs from notes as separate reference entries
- Platform-specific tags: re/hn, re/lb, re/rd for reference links
- Maps folder → Linkwarden collections, tags → parsed tag arrays
- ISO timestamp → Unix timestamp conversion for compatibility

**Technical Decisions:**
- Leveraged existing linkwarden_import.py infrastructure for API handling
- Used minimal dependencies (urllib3 for URL normalization)
- Followed .agents/docs/links.md guidelines for URL processing
- Reference links get 'from {source_url}' descriptions for traceability

**Modified Files:**
- rss2linkwarden.py: New converter script (150 lines)
- backlog/tasks/task-0015: Updated with detailed requirements

**Usage:** ./rss2linkwarden.py input.csv | ./linkwarden_import.py --days -1
## Detailed Mapping Requirements

### CSV to Linkwarden Field Mapping:
- `title` → `name` (direct mapping)
- `url` → `url` (direct mapping)  
- `excerpt` → `textContent` (direct mapping)
- `note` + `highlights` → `description` (combined with special formatting)
- `folder` → `collection.name` (map to Linkwarden collection)
- `tags` → `tags[].name` (parse comma/pipe separated)
- `created` → `importDate` (timestamp mapping)
- `favorite` → ignore for now (may map to color in future)
- `cover` → ignore

### Note Processing Requirements:
- Process `note` field line by line
- If line looks like URL or markdown URL `[title](url)`, import as separate link
- Reference links get tags: `re/hn` (Hacker News), `re/lb` (Lobsters), `re/rd` (Reddit)
- Reference link description: "from {original_url}" where original_url contains the reference

### Description Formatting:
- Combine `note` and `highlights` in description
- Each highlight line prefixed with `> ` (markdown quote format)
- Extract and enhance HN/Lobsters URLs like existing script

### Collection Management:
- Map CSV `folder` field to Linkwarden collections
- Create collections dynamically if they don't exist
