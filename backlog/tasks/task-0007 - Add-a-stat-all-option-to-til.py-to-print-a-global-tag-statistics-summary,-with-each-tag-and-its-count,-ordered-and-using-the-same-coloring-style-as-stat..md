---
id: task-0007
title: >-
    Add a --stat-all option to til.py to print a global tag statistics summary,
    with each tag and its count, ordered and using the same coloring style as
    --stat.
status: To Do
assignee: []
created_date: "2025-07-30"
labels: []
dependencies: []
---

## Description

Enable users to see a global summary of all tags and their usage counts in til.py, matching the style and coloring of the existing --stat option, but aggregated across all entries.

## Acceptance Criteria

-   [ ] --stat-all option is available in til.py
-   [ ] Output lists all tags and their counts globally
-   [ ] Output is ordered and colored as in --stat
-   [ ] Feature is tested and documented

## Implementation Notes (2025-07-30, AGENT)

-   Implemented --stat-all flag in til.py using argparse.
-   Added print_global_tag_stats() function, which uses a shared \_extract_tags_from_file() utility for consistent tag extraction and dedup/no-dedup logic.
-   Output is sorted by count (desc) then alphabetically, and uses the same color formatting as --stat.
-   Refactored all stats functions (monthly/global/merge) to use the same tag extraction and color formatting utilities for consistency.
-   All stats functions now respect --dedup/--no-dedup flags for explicit tag handling.
-   Tested all flag combinations (--stat, --stat-all, --merge-stat, --dedup, --no-dedup) for correctness.
-   See til.py for AGENT-NOTE comments and function docstrings for details.
