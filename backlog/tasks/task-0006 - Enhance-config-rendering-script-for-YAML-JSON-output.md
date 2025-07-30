---
id: task-0006
title: Enhance config rendering script for YAML/JSON output
status: Done
assignee: []
created_date: "2025-07-30"
updated_date: "2025-07-30"
labels: []
dependencies: []
---

## Description

Unify and improve the config rendering script to support both YAML and JSON output formats, and update build tasks to use it. Switch the opencode config template to YAML (superset of JSON) for comments and advanced features, update all automation and scripts to use YAML, and ensure robust environment variable substitution and defaulting. This enables more flexible, maintainable, and robust config generation for the project. (per G-task, G-verify, G-commit)

## Acceptance Criteria

-   [ ] Script supports --yaml and --json flags
-   [ ] Script outputs valid YAML or JSON as selected
-   [ ] Help message is available via --help
-   [ ] Build tasks use the new script for config generation
-   [ ] Output files are valid and used in build process
-   [ ] Config template is YAML (not JSON), supports comments and YAML features
-   [ ] Environment variable substitution and defaulting is robust and tested
-   [ ] All automation and documentation updated to reference YAML template
-   [ ] End-to-end test verifies opencode loads rendered config without errors

## Implementation Plan

1. Refactor render_yaml.py to use argparse and support mutually exclusive --yaml/--json flags.
2. Add help message and usage info.
3. Update build tasks (e.g., prep-oc in dotfiles/llm.just) to use the new script for config generation.
4. Switch opencode config template to YAML (dotfiles/.config/opencode/opencode.in.yaml), supporting comments and YAML features.
5. Update render_yaml.py to always parse YAML, post-process MODEL_NAME for env var.
6. Test both YAML and JSON output modes and help message.
7. Verify output files are valid and used in the build process.
8. Test environment variable substitution and defaulting.
9. Update documentation and anchor comments as needed.

## Implementation Notes

Refactored render_yaml.py to use argparse and support --yaml/--json flags. Added help message. Updated prep-oc task in dotfiles/llm.just to use the new script for generating opencode.json. Switched config template to YAML (dotfiles/.config/opencode/opencode.in.yaml), supporting comments and YAML features. Updated render_yaml.py to always parse YAML and post-process MODEL_NAME for env var. Verified both YAML and JSON output modes, help message, build integration, and robust environment variable substitution/defaulting. Files changed: render_yaml.py, dotfiles/llm.just, dotfiles/.config/opencode/opencode.in.yaml. All acceptance criteria met. (per G-task, G-verify, G-commit)

Refactored render_yaml.py to use argparse and support --yaml/--json flags. Added help message. Updated prep-oc task in dotfiles/llm.just to use the new script for generating opencode.json. Created dotfiles/.config/opencode/opencode.json.in as the template for config generation. Verified both YAML and JSON output modes, help message, and build integration. Files changed: render_yaml.py, dotfiles/llm.just, dotfiles/.config/opencode/opencode.json.in. All acceptance criteria met.

Refactored render_yaml.py to use argparse and support --yaml/--json flags. Added help message. Updated prep-oc task in dotfiles/llm.just to use the new script for generating opencode.json. Created dotfiles/.config/opencode/opencode.json.in as the template for config generation, ported from the original heredoc in prep-oc. Verified both YAML and JSON output modes, help message, and build integration. Files changed: render_yaml.py, dotfiles/llm.just, dotfiles/.config/opencode/opencode.json.in. All acceptance criteria met.
