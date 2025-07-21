---
id: task-0001
title: Fix tm-mon tmux monitoring session
status: Done
assignee:
  - '@claude'
created_date: '2025-07-21'
updated_date: '2025-07-21'
labels: []
dependencies: []
---

## Description

The tm-mon command in dotfiles/term.just fails with 'size missing' error and only creates the left pane instead of the intended 3-pane monitoring layout with btop, macmon, and mactop

## Acceptance Criteria

- [ ] tm-mon command runs without errors
- [ ] Creates 3 panes: left (btop)
- [ ] top-right (macmon)
- [ ] bottom-right (mactop)
- [ ] All monitoring tools display correctly in their respective panes

## Implementation Plan

1. Analyze current tm-mon command syntax\n2. Identify tmux split-window syntax errors\n3. Fix the percentage and pane targeting issues\n4. Test the corrected command\n5. Commit the fix

## Implementation Notes

Fixed the tmux syntax errors in dotfiles/term.just tm-mon command. Removed problematic -p 50 percentage flags and corrected pane targeting. The command now properly creates a 3-pane layout: left pane with btop, top-right with macmon, and bottom-right with sudo mactop. Tested manually and committed the fix.
