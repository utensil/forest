# Agent Instructions

*Last updated 2025-07-20*

> **Purpose** – This file is the onboarding manual[^1] for every AI assistant (Claude, Amp, Codex, Amazon Q, OpenCode, etc.) and every human who edits this repository.
> It encodes our coding standards, guard-rails, and workflow tricks so the *human 30 %*[^2] (architecture, tests, domain judgment) stays in human hands.

> **Repository-specific information** – For detailed information about this specific repository, including project overview, build commands, coding standards, and other repo-specific guidelines, see [.agents/docs/repo.md](./.agents/docs/repo.md).

---

## 1. Non-negotiable GOLDEN rules

ALWAYS cite the rules which you have actually followed during the reply at the end of your reply, like this: "(per G-ask, G-verify)".

### G-ask: Always ask for clarification when unsure
- ✅ **Should**: Ask the developer for clarification before making changes when unsure about project-specific details or lacking context for a particular feature/decision, especially when there are contradicting requirements
 - ❌ **Must NOT**: make assumptions, write changes or use tools when uncertain

### G-scope: Stay within designated code areas  
- ✅ **May**: Generate code only inside relevant source directories or explicitly pointed files
- ✅ **May**: Execute build scripts and commands as documented in section "Build, test & utility commands" in repo.md
- ❌ **Must NOT**: Modify test files, CI configs, or core build scripts without explicit permission

### G-note: Use anchor comments appropriately
- ✅ **May**: Add/update `AGENT-NOTE:` anchor comments (see section "Anchor comments" below) near non-trivial edited code
- ❌ **Must NOT**: Delete or mangle existing `AGENT-*` comments

### G-lint: Follow project linting and style
- ✅ **May**: Follow coding standards in repo.md, and lint/style configs using the configured linters
- ❌ **Must NOT**: Re-format code to any other style

### G-size: Get approval for large changes
- ✅ **May**: Make changes, but ask for confirmation if >300 LOC or >3 files
- ❌ **Must NOT**: Refactor large modules without human guidance

### G-focus: Maintain task context boundaries
- ✅ **May**: Stay within current task context, inform dev if fresh start would be better
- ❌ **Must NOT**: Continue work from a prior prompt after "new task" – start a fresh session

### G-verify: Verify your changes

- ✅ **Should**: Verify your changes by learning how the code is supposed to run/test/lint (see also section "Build, test & utility commands" in repo.md), then design a way to verify. Prefer to re-use or add tests to verify. If you need temporary script or mock data to do so, keep them all under `.agents/scripts`, don't remove them afterward, and don't commit them per G-commit.
- ❌ **Must NOT**: Run scripts or commands that contains dangerous code, or unrelated to code exploration and change verification.

### G-commit: Commit your changes to version control system

- ✅ **Should**: After editing files, before pausing and asking for further instructions, commit your changes to version control system. ALWAYS commit per section "Commit discipline" below. ALL commits MUST include [AGENT] tag.
- ❌ **Must NOT**: Commit files that are not directly related to your current task. Only commit files you have intentionally modified as part of the specific work requested. Do not commit unrelated changes, even if they exist in your working directory.

### G-task: Follow backlog workflow for structured tasks

- ✅ **Should**: Use `backlog` commands with `--plain` flag per `.agents/docs/backlog.md` when working on backlog tasks
- ✅ **Should**: Complete Definition of Done checklist before marking tasks Done
- ✅ **Should**: Add concise execution notes to completed tasks: what was done, key changes, files modified, gotchas for future tasks
- ❌ **Must NOT**: Implement beyond acceptance criteria without updating task first
- ❌ **Must NOT**: Use backlog when not working on backlog-managed tasks

### G-sandbox: Use Docker stacks for isolated development environments

- ✅ **Should**: First try running existing stacks from `stacks/` directory using `docker-compose -f <stack-file>`
- ✅ **Should**: Create new stacks under `.agents/stacks/` only if existing ones don't meet requirements
- ✅ **May**: Use standard docker-compose commands:
  - Build: `docker-compose -f <stack-file> build`
  - Start daemon: `docker-compose -f <stack-file> up -d`
  - Stop: `docker-compose -f <stack-file> down`
  - Execute commands: `docker-compose -f <stack-file> exec <service> <command>`
- ✅ **Should**: Stop stacks with `down` when task is complete, but keep stack files for reuse
- ✅ **May**: Suggest graduating newly created stacks from `.agents/stacks/` to `stacks/` if they have generic potential for future reuse
- ❌ **Must NOT**: Modify host system when explicitly asked to follow G-sandbox

### G-safe: Prioritize data safety and prevent destructive operations

- ✅ **Should**: Use `rip` instead of `rm` for file/directory removal (automatic backups to `/tmp/graveyard-$USER` with recovery via `--unbury`)
- ✅ **May**: Provide instructions for destructive operations but never execute them
- ✅ **May**: Use `--dry-run` flags to preview changes before execution
- ❌ **Must NOT**: Execute any potentially destructive operations (deletions, overwrites, system changes)
- ❌ **Must NOT**: Remove files without backup mechanism
- ❌ **Must NOT**: Modify system-critical files or permissions

---

## 2. Anchor comments

Add specially formatted comments throughout the codebase, where appropriate, for yourself as inline knowledge that can be easily `grep`ped for. 

### Guidelines:

- Use `AGENT-NOTE:`, `AGENT-TODO:`, or `AGENT-QUESTION:` (all-caps prefix) for comments aimed at AI and developers.
- Keep them concise (≤ 120 chars).
- **Important:** Before scanning files, always first try to **locate existing anchors** `AGENT-*` in relevant subdirectories.
- **Update relevant anchors** when modifying associated code.
- **Do not remove `AGENT-NOTE`s** without explicit human instruction.
- Make sure to add relevant anchor comments, whenever a file or piece of code is:
  * too long, or
  * too complex, or
  * very important, or
  * confusing, or
  * could have a bug unrelated to the task you are currently working on.

Example:
```javascript
// AGENT-NOTE: perf-hot-path; WASM loading can be slow on first run
async function loadEgglogWasm() {
    ...
}
```

---

## 3. Commit discipline

The version control system is `jj`, NOT git.

You should ALWAYS follow this `jj` commit workflow:

- Before committing:
    - use `jj` (which combines `jj status` and `jj log` in a customized way) to learn about status and recent revisions
        - so you'll be clear which revision to commit, and won't commit an empty or unrelated revision
        - fallback to use `jj log --no-graph -T '{commit_id} {description}' -n <N>` to view the last N revisions in a concise format
    - run `jj diff` or `jj diff -r <rev>` to review all changes in the working copy or the revision you intend to commit.
- During committing:
    - **Granular commits**: One logical change per commit.
    - **Targeted commit**:
        - Only include changes for files you intentionally edited, for both the files to commit, and the content of the commit message
        - To commit file `A.txt`, `B that has spaces.txt`, and directory `src`, use `jj commit 'A.txt | "B that has spaces.txt" | src ' -m "<message>"`. 
    - **No sensitive information**: If the diff to be committed includes passwords, credentials, real environment variables, IP addresses, absolute paths outside the project, or other personal/private information, refuse to commit and alert the user; never add such information into the commit message too.
- After committing, if asked to improve commit message:
    - To edit the commit message of any commit, use `jj desc -r <rev> -m "<message>"` for a specific revision.

To determine the commit message, you should ALWAYS follow this checklist:

*   **Use conventional commits**: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, etc.
*   **Descriptive commit messages**: ALWAYS include both:
    - Short title explaining the *why* (what problem this solves)
    - Detailed description of *what* changed (specific files, functions, behavior, related issue links, etc.)
        - you should inspect the full diff for the edited files for summarization, and don't use only recent rounds of conversation to describe the whole commit that contain changes from earlier conversations
        - NEVER cite the rules (e.g. (per G-verify)) in the commit message
    - Example: `fix: resolve WASM loading timeout in dev mode [AGENT]` + description of which files were modified and how
*   **MANDATORY [AGENT] tag**: ALL agent-generated commits MUST end the title of the commit message with `[AGENT]` tag. NO EXCEPTIONS.
    - ✅ Correct: `feat: optimize shader loading [AGENT]`
    - ❌ Wrong: `feat: optimize shader loading` (missing [AGENT] tag)

Disciplines for humans:

*   **Review AI-generated code**: Never merge code you don't understand.

## 4. Writing task automation scripts

When implementing complex data processing or automation tasks, create standalone Python scripts that integrate with the project workflow.

### Script Structure Requirements

**Always use uv shebang with inline dependencies:**
```python
#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["requests>=2.31.0"]
# ///
```

**Never use `python3` to run scripts** - the uv shebang handles execution and dependency management automatically.

### Documentation Standards

**Comprehensive docstrings required:**
```python
"""
RSS Star Processor
==================

This script processes starred items in RSS reader and converts them into learning diary format with proper date grouping and link formatting.

Usage: just stars (calls this script internally)
"""
```

**Critical functionality documentation:**
```python
# AGENT-NOTE: CRITICAL FEATURES TO MAINTAIN
# 1. IDEMPOTENT: Multiple runs must produce identical results
# 2. ERROR HANDLING: Graceful degradation for missing data
# 3. BUILD INTEGRATION: Validates syntax after processing
# 4. DETERMINISTIC: Sorted processing ensures consistent output
```

### Implementation Patterns

Scripts should handle input/output gracefully, integrate with existing project formats, and maintain deterministic behavior for consistent results across multiple runs.

### Integration Guidelines

- **Never clean up scripts** - leave them for human inspection and debugging
- Scripts should integrate with `just` commands for consistency
- Include validation commands to verify output correctness
- Add reset/undo functionality for reversible operations
- Use project-specific file paths and naming conventions

### Testing Requirements

Scripts should be designed for:
- **Idempotency testing**: Run twice, second run should show no changes
- **Build validation**: Always verify output doesn't break the build
- **Error recovery**: Handle missing files, malformed data, permission issues

Example testing pattern:
```bash
# Test idempotency
uv run script.py && uv run script.py
# Expected: Second run shows "No changes needed"

# Validate build integrity  
just build
# Expected: Build completes without syntax errors
```

---

## 5. Meta: Guidelines for updating AGENT.md files

This file should be updated when:
- New major features or tools are added to the project
- Build processes or development workflows change significantly  
- New coding standards or conventions are established
- Common pitfalls or debugging patterns are identified

### Maintenance checklist:
- [ ] Update last modified date at the top
- [ ] Review golden rules for relevance
- [ ] Update build commands if changed
- [ ] Document new pitfalls discovered
- [ ] Update file pattern references

---

[^1]: This file is adapted from [AGENTS.md by Julep AI](https://github.com/julep-ai/julep/blob/dev/AGENTS.md)
[^2]: The "human 30%" refers to keeping strategic decisions, architectural choices, test design, and domain expertise in human hands while leveraging AI for implementation, documentation, and routine tasks.
