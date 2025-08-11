# Directory integrity and timestamp check: strict log format

## Problem

Directory synchronization and verification require robust, script-friendly checks for both file content and modification times. The workflow must emit all results in a strict, machine-parseable log format suitable for automation and downstream processing.

## Functionality

-   **Hash comparison:**
    -   Generate content hashes for all files in both source and destination directories.
    -   Compare hashes and report mismatches.
-   **Timestamp checks:**
    -   Detect and report files with suspiciously recent modification times (within a configurable threshold).
    -   Detect and report files with timestamp mismatches (differences >1s).
-   **Idempotency & robustness:**
    -   Workflow is idempotent, deterministic, and robust to missing files or directories.

## Log format specification

-   **Prefixes:**
    -   `[INFO]` for general summaries and progress.
    -   `[WARN]` for summary of issues (e.g., number of mismatches).
    -   `[DEBUG]` for per-file details.
-   **Per-file `[DEBUG]` lines:**
    -   All fields are pipe-separated.
    -   **Event types** are always hyphenated, lower-case, and unambiguous:
        -   `hash-mismatch` for content hash mismatches.
        -   `timestamp-mismatch` for timestamp differences >1s.
        -   `too-recent` for files modified within the suspicious recency threshold.
-   **Field order and examples:**
    -   **Hash mismatch:**  
        `[DEBUG] ./file|hash-mismatch|<left-hash>|<right-hash>`
    -   **Timestamp mismatch:**  
        `[DEBUG] ./file|timestamp-mismatch|<diff>|<left-timestamp>|<right-timestamp>`
    -   **Too recent:**  
        `[DEBUG] ./file|too-recent|<timestamp>`
-   **Timestamps:**
    -   Always formatted as `YYYY-MM-DD HH:MM:SS`.
-   **Hash order:**
    -   `<left-hash>` is always the source (left) hash, `<right-hash>` is always the destination (right) hash.

## Key implementation notes

-   Hash files are generated in `/tmp/jw/` with timestamped, descriptive names to avoid polluting source/destination directories.
-   The workflow parses `jw -D` output and reformats hash mismatches to the required `[DEBUG]` format.
-   `check-ts.py` is responsible for timestamp checks and emits all findings in the required log format.
-   The workflow was tested end-to-end with simulated mismatches to ensure correctness and script-friendliness.
-   All log output is suitable for downstream automation or integration.

## Acceptance criteria

-   All output matches the required format
-   All log lines are strictly prefixed and pipe-separated
-   All event types are hyphenated and unambiguous
-   Timestamps are formatted as `YYYY-MM-DD HH:MM:SS`
-   Hash order is always left (source) then right (destination)
-   Workflow is idempotent and robust

## Gotchas for future tasks

-   If new event types are added, ensure they follow the same log format and naming conventions.
-   Always verify hash and timestamp order when changing parsing logic.
-   Maintain idempotency and deterministic output for reliable automation.

## Definition of done

-   All output matches the required format
-   All acceptance criteria above are met
-   Task is marked done in backlog

## Execution notes

-   Refactored and merged check-ts.py into check-dirs.py, now fully Python-coordinated
-   justfile updated to call check-dirs.py, removing all references to check-ts.py
-   All hash and timestamp checking, mismatch limiting, and log output are coordinated in Python
-   [INFO], [WARN], and [DEBUG] lines are strictly formatted as specified
-   Output is idempotent, robust, and script-friendly for automation
-   Workflow tested end-to-end, including edge cases and simulated mismatches
-   Task complete and committed per AGENT.md and G-task

(per G-task)
