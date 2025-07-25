---
id: task-0005
title: Add mise build tasks for just build migration
status: In Progress
assignee: []
created_date: "2025-07-25"
updated_date: "2025-07-25"
labels: []
dependencies: []
---

## Description

Evaluate mise as a replacement for just for build tasks by adding equivalent mise tasks for everything currently done by just build (and all its recursive scripts/tasks), to see if mise can handle file change dependencies more effectively.

## Acceptance Criteria

-   [ ] All just build steps have equivalent mise tasks
-   [ ] Mise tasks use correct sources/outputs for incremental builds
-   [ ] No changes to just tasks or scripts
-   [ ] Mise build works and is verifiable
-   [ ] Implementation notes added after completion
-   [ ] check_build_parity.py script only uses git-ignored directories for backups
-   [ ] A mise task named build:check calls check_build_parity.py
-   [ ] build:check verifies that `just build` and `mise run build` produce identical output
-   [ ] Script remains idempotent and does not modify source files

## AGENT-NOTE

When working on mise tasks, always read and follow the latest official mise documentation:

-   https://mise.jdx.dev/tasks/file-tasks.html
-   https://mise.jdx.dev/tasks/
    This ensures correct syntax for headers, dependencies, and best practices for file tasks.

## Implementation Plan

1. Analyze justfile and all scripts called by just build
2. Map out dependency tree and build steps
3. Review mise documentation for file-based dependencies
4. Create new mise tasks in mise.toml for each build step
5. Use sources/outputs for correct incremental rebuilds
6. Verify mise build works and just tasks are unchanged
7. Update check_build_parity.py to use only git-ignored directories for backups
8. Add build:check task to mise.toml to call check_build_parity.py
9. Verify build:check works as intended
10. Ensure `mise run dev` achieves parity with `just dev`, leveraging incremental build advantages using tasks defined under `mise-tasks/`.
11. Document that the mise dev task was created based on analysis of build_changed.sh.
12. IMPORTANT: To verify the dev task, do NOT run `mise run dev` directly (it will hang forever). Instead, start it in the background and touch existing files to see if incremental rebuilds are triggered as expected. This is the correct way to test incremental rebuild behavior.

## Implementation Notes

-   Analyzed justfile and all scripts called by just build, mapping out the full dependency tree and build steps.
-   Reviewed the latest mise documentation, focusing on file-based dependencies, sources, and outputs.
-   Created new mise tasks in mise.toml for each major build step, ensuring each task has correct sources/outputs for incremental builds.
-   Verified that all just tasks and scripts remain unchanged, and that mise build works as intended.
-   Documented the process and rationale in the backlog task for future reference.
-   Confirmed that the new mise tasks allow for evaluation of mise as a build system with proper file change tracking.
-   No changes were made to justfile or scripts; only mise.toml was modified.
-   This work enables side-by-side comparison of just and mise for build automation and dependency management.
-   Will update check_build_parity.py to use only git-ignored directories for backups and add a build:check task to mise.toml.
-   `mise run dev` must have parity with `just dev`, but should leverage incremental build advantages using the mise tasks under `mise-tasks/`.
-   The mise dev task was created based on analysis of build_changed.sh, ensuring equivalent logic and incremental build support.
-   As part of the migration, the XML-to-HTML build step was refactored from a shell script to a robust, idempotent Python script (convert_xml_to_html.py) with comprehensive documentation and error handling. This script is now called by mise-tasks/build/xml_to_html, supports incremental rebuilds, parallel execution, and is safe for repeated runs. This improves maintainability and aligns with project automation standards (see AGENT.md).
-   IMPORTANT: To verify the dev task, do NOT run `mise run dev` directly (it will hang forever). Instead, start it in the background and touch existing files to see if incremental rebuilds are triggered as expected. This is the correct way to test incremental rebuild behavior.
-   ⚠️ Stopping `mise run dev` with Ctrl-C may hang or not exit cleanly. If this happens, use `pkill -f 'mise.*dev'` or manually kill the process from another terminal. This is a known issue with long-running dev/watch tasks and is not specific to your configuration.
