---
id: task-0004
title: Reduce til.py log verbosity and add tag stats summary
status: Done
assignee:
    - "@opencode"
created_date: "2025-07-25"
updated_date: "2025-07-25"
labels: []
dependencies: []
---

## Description

Update `til.py` logging so that by default it only outputs concise statistics:

-   Show tag count for each month
-   Show how many tags are merged by default
    If the `--verbose` flag is provided, output detailed logs in the format:
-   `date: matched the keyword pattern -> tag`

## Acceptance Criteria

-   [x] Default log output is concise: only monthly tag counts and merge stats
-   [x] `--verbose` flag enables detailed logs for each tag extraction event
-   [x] Detailed logs show: `date: matched the keyword pattern -> tag`
-   [x] All changes documented in backlog task file with execution notes

## Implementation Notes

### Motivation & Goals

-   Reduce log noise for routine runs, making output more useful for summary review
-   Provide a way to debug or audit tag extraction with `--verbose`

### Key Design Decisions

-   Default log output is summary only
-   `--verbose` flag triggers detailed per-tag logs

### Testing & Validation

-   Add/expand tests to verify both default and verbose log outputs
-   Ensure summary stats are correct and detailed logs match extraction events
-   All tests pass for both modes

### Gotchas & Future Guidance

-   When extending tag logic, update logging and tests accordingly
-   Only til.py modified; see commit for details

## AGENT-NOTE

This task follows G-task, G-scope, G-commit, and G-verify rules in AGENTS.md. All code and documentation changes must be committed with [AGENT] tag and execution notes. Task is not done until all acceptance criteria are met and tested.

### Execution Notes

-   Refactored til.py logging: default output is monthly tag counts and merge stats
-   Added --verbose flag for detailed logs (date: matched the keyword pattern -> tag)
-   Updated and expanded test suite to verify both default and verbose outputs
-   All tests pass for both modes
-   No changes outside til.py
