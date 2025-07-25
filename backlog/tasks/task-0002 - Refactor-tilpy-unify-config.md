---
id: task-0002
title: Refactor til.py to unify config for tag/keyword/project extraction
status: Done
assignee:
    - "@opencode"
created_date: "2025-07-25"
updated_date: "2025-07-25"
labels: []
dependencies: []
---

## Description

Refactor til.py to unify all keyword/tag/project logic behind a single config system. The config should support both direct string matches and regex patterns, using "string" for exact and "/regex/" for regex. Each config entry can be a string (direct tag) or a map with tag and pattern (array of strings/regexes). This will simplify maintenance and ensure consistent tag extraction.

## Implementation Notes

### Motivation & Goals

-   Previous tag extraction logic was fragmented, hard to maintain, and inconsistent for new technical domains or project references.
-   Goal: Centralize all tag/keyword/project logic in a single config system for maintainability, extensibility, and deterministic output.

### Key Design Decisions

-   Introduced `TAG_CONFIG` for unified tag/keyword extraction:
    -   Supports both direct string matches and regex-based patterns.
    -   Regex patterns use capturing groups for project prefix extraction (e.g. "ag" from "[[ag-0018]]").
    -   Config is easily extensible: add new string or regex entries for new domains.
-   Introduced `TAG_MERGE` for canonicalizing/merging similar tags:
    -   Maps alternative tags to preferred canonical tags (e.g. "formalization", "verification" → "formal").
    -   Ensures search and organization are consistent across diary entries.
-   Extraction logic refactored to use config for both string and regex matching, with robust filtering for non-technical tags.
-   Merging logic refactored to use config, with deterministic ordering and duplicate prevention.

### Testing & Validation

-   Automated test suite added to til.py covering:
    -   Basic technical content
    -   Citation extraction from bib titles
    -   Project references (e.g. [[ag-0018]])
    -   Explicit topic tags
    -   Mixed technical content
    -   Non-technical filtering
-   Edge cases handled:
    -   Project references anywhere in content
    -   Bib citation tags only extract valid technical tags
    -   Non-technical tags (e.g. "time") are filtered out
-   All tests pass, including edge cases for citations, project references, and non-technical filtering.
-   Idempotency and determinism verified: repeated runs produce identical results.

### Gotchas & Future Guidance

-   Regex patterns for project tags must use capturing groups for prefix extraction.
-   When extending config, ensure new tags are technical and not overly broad (to avoid false positives).
-   For new technical domains, add both string and regex patterns as needed.
-   Merging logic can be extended by adding new preferred tags and their alternatives in `TAG_MERGE`.
-   If extraction logic changes, update tests to cover new edge cases.
-   Only til.py modified; see commit for details.
