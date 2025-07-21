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

### Key Issues Identified
- Invalid `-p 50` percentage flags in split-window commands caused "size missing" errors
- Incorrect pane targeting syntax prevented proper layout creation
- Manual testing revealed the correct approach: use split-window without percentages and proper pane targeting

### Useful Testing Commands for tmux Layout Debugging
The following commands proved essential for debugging tmux layout issues:

**Session Management:**
- `tmux list-sessions` - List all active tmux sessions
- `tmux kill-session -t mon` - Clean kill the monitoring session for fresh testing
- `tmux list-panes -t mon` - List panes in the monitoring session to verify layout

**Testing Approaches:**
- Test commands from outside tmux sessions vs inside existing sessions
- Run manual step-by-step tmux commands to verify each split operation:
  ```bash
  tmux new-session -d -s mon 'btop'
  tmux split-window -t mon:0 -h 'macmon'
  tmux split-window -t mon:0.1 -v 'sudo mactop'
  ```
- Use `tmux attach -t mon` to visually inspect the layout
- Test the complete automated command after verifying manual steps work

**Key Learnings:**
- Avoid percentage flags in split-window commands when not properly supported
- Use proper pane targeting (e.g., `mon:0.1` for second pane)
- Test incrementally - verify each split operation individually before combining
- Always test from a clean tmux state (kill and recreate sessions)
