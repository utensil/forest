---
id: task-0006
title: Enhance config rendering script for YAML/JSON output
status: Done
assignee: []
created_date: '2025-07-30'
updated_date: '2025-07-30'
labels: []
dependencies: []
---

## Description

Unify and improve the config rendering script to support both YAML and JSON output formats, and update build tasks to use it. This enables more flexible and maintainable config generation for the project.

## Acceptance Criteria

- [ ] Script supports --yaml and --json flags; Script outputs valid YAML or JSON as selected; Help message is available via --help; Build tasks use the new script for config generation; Output files are valid and used in build process

## Implementation Plan

1. Refactor render_yaml.py to use argparse and support mutually exclusive --yaml/--json flags.\n2. Add help message and usage info.\n3. Update build tasks (e.g., prep-oc in dotfiles/llm.just) to use the new script for config generation.\n4. Test both YAML and JSON output modes and help message.\n5. Verify output files are valid and used in the build process.

## Implementation Notes

Refactored render_yaml.py to use argparse and support --yaml/--json flags. Added help message. Updated prep-oc task in dotfiles/llm.just to use the new script for generating opencode.json. Verified both YAML and JSON output modes, help message, and build integration. Files changed: render_yaml.py, dotfiles/llm.just. All acceptance criteria met.

Refactored render_yaml.py to use argparse and support --yaml/--json flags. Added help message. Updated prep-oc task in dotfiles/llm.just to use the new script for generating opencode.json. Created dotfiles/.config/opencode/opencode.json.in as the template for config generation. Verified both YAML and JSON output modes, help message, and build integration. Files changed: render_yaml.py, dotfiles/llm.just, dotfiles/.config/opencode/opencode.json.in. All acceptance criteria met.

Refactored render_yaml.py to use argparse and support --yaml/--json flags. Added help message. Updated prep-oc task in dotfiles/llm.just to use the new script for generating opencode.json. Created dotfiles/.config/opencode/opencode.json.in as the template for config generation, ported from the original heredoc in prep-oc. Verified both YAML and JSON output modes, help message, and build integration. Files changed: render_yaml.py, dotfiles/llm.just, dotfiles/.config/opencode/opencode.json.in. All acceptance criteria met.
