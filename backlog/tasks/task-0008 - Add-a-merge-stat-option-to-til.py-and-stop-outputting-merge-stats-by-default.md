---
id: task-0008
title: Add a --merge-stat option to til.py and stop outputting merge stats by default
status: To Do
assignee: []
created_date: "2025-07-30"
labels: []
dependencies: []
---

## Description

Currently, til.py outputs merge statistics by default. Change the behavior so that merge stats are only shown when the new --merge-stat option is provided, keeping the default output clean.

## Acceptance Criteria

-   [ ] --merge-stat option is available in til.py
-   [ ] Merge stats are only output when --merge-stat is used
-   [ ] Default output does not include merge stats
-   [ ] Feature is tested and documented

## Implementation Notes (2025-07-30, AGENT)

-   Added --merge-stat flag to til.py using argparse.
-   Refactored print_merge_stats() to use a shared \_extract_tags_from_file() utility for consistent tag extraction and dedup/no-dedup logic.
-   Output is only shown when --merge-stat is provided, and is sorted by number of merged tags (desc).
-   All stats functions (monthly/global/merge) now use the same color formatting and error handling for consistency.
-   All stats functions now respect --dedup/--no-dedup flags for explicit tag handling.
-   Tested all flag combinations (--stat, --stat-all, --merge-stat, --dedup, --no-dedup) for correctness.
-   See til.py for AGENT-NOTE comments and function docstrings for details.
