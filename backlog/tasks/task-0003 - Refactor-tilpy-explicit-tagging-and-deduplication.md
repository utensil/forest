---
id: task-0003
title: Refactor til.py for explicit #tag extraction and deduplication logic
status: Done
assignee:
    - "@opencode"
created_date: "2025-07-25"
updated_date: "2025-07-25"
labels: []
dependencies: []
---

## Description

Update `til.py` to only recognize explicit tags in the form `#tag` or `#multi-word-tag`, surrounded by spaces or line ends. Remove support for the legacy `- abc related` pattern. Implement deduplication so explicit tags are not included in other recognized patterns. Add CLI options to control whether explicit tags are included or deduplicated in the final output.

## Acceptance Criteria

-   [x] Only explicit tags (`#tag`, `#multi-word-tag`) are recognized as tags.
-   [x] Old pattern (`- abc related`) is no longer recognized.
-   [x] Explicit tags are extracted only when surrounded by space or line end.
-   [x] Deduplication logic ensures explicit tags are not repeated in other tag lists.
-   [x] CLI option `--dedup` (default) to deduplicate explicit tags from output (explicit tags are NOT included).
-   [x] CLI option `--no-dedup` to include explicit tags in output (explicit tags ARE included).
-   [x] All changes documented in backlog task file with execution notes.

## Implementation Notes

### Motivation & Goals

-   Remove legacy topic-related pattern and support only explicit tagging for clarity and maintainability.
-   Provide flexible CLI options for tag output control to suit different search and organization needs.

### Key Design Decisions

-   Use regex to extract explicit tags (`#tag`, `#multi-word-tag`) only when surrounded by space or line end.
-   Deduplicate explicit tags from other recognized patterns in the final output.
-   CLI flags now use `--dedup` (default) and `--no-dedup` for explicit tag control.

### Testing & Validation

-   Added test cases for explicit tag extraction, deduplication, and CLI options.
-   Verified that legacy patterns are no longer recognized.
-   Ensured deterministic and idempotent output.

### Gotchas & Future Guidance

-   Regex for explicit tags avoids matching fragments of URLs or other text.
-   When extending tag logic, update tests and documentation accordingly.
-   Only til.py modified; see commit for details.

## AGENT-NOTE

This task follows G-task, G-scope, G-commit, and G-verify rules in AGENTS.md. All code and documentation changes must be committed with [AGENT] tag and execution notes. Task is not done until all acceptance criteria are met and tested.

### Execution Notes

-   Removed legacy '- abc related' pattern recognition from til.py
-   Implemented robust explicit tag extraction (regex for #tag/#multi-word-tag, space/line boundaries)
-   Updated deduplication logic so explicit tags are not included in other recognized patterns
-   Added CLI options to control explicit tag inclusion/deduplication in final output
-   Added/expanded tests for explicit tag extraction, deduplication, and both CLI options (`--dedup`, `--no-dedup`)
-   All changes tested and verified for idempotency and determinism
-   CLI refactor verified: default is dedup ON, explicit tags omitted unless `--no-dedup` is specified
