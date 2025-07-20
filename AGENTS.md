# Agent Instructions for Forest

*Last updated 2025-07-20*

> **Purpose** – This file is the onboarding manual[^1] for every AI assistant (Claude, Amp, Codex, Amazon Q, OpenCode etc.) and every human who edits this repository.
> It encodes our coding standards, guard-rails, and workflow tricks so the *human 30 %*[^2] (architecture, tests, domain judgment) stays in human hands.

> **Repository-specific information** – For detailed information about this specific repository, including project overview, build commands, coding standards, and other Forest-specific guidelines, see [for-llm/repo.md](./for-llm/repo.md).

---

## 0. Non-negotiable GOLDEN rules

ALWAYS cite the rules which you are following at the end of your reply, like this: "(per G-ask, G-verify)".

### G-ask: Always ask for clarification when unsure
- ✅ **Should**: Ask the developer for clarification before making changes when unsure about project-specific details or lacking context for a particular feature/decision
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

### G-search: Prefer ast-grep for syntax-aware search, with ripgrep as fallback

✅You run in an environment where ast-grep (`sg`) is available. Whenever a search requires syntax-aware or structural matching, default to `sg --lang <lang> -p '<pattern>'`. Avoid falling back to text-only tools like ripgrep (`rg`) unless `sg` fails to do the job, or plain-text search is explicitly requested.

### G-verify: Verify your changes

- ✅ **Should**: Verify your changes by learning how the code is supposed to run/test/lint (see also section "Build, test & utility commands" in repo.md), then design a way to verify. Prefer to re-use or add tests to verify. If you need temporary script or mock data to do so, keep them all under `.agents/`, and don't remove them afterward.
- ❌ **Must NOT**: Run scripts or commands that contains dangerous code, or unrelated to code exploration and change verification.

### G-commit: Commit your changes to version control system

- ✅ **Should**: After editing files, before pausing and asking for further instructions, commit your changes to version control system. ALWAYS commit per section "Commit discipline" below. ALL commits MUST include [AGENT] tag.
- ❌ **Must NOT**: Commit files that are not directly related to your current task. Only commit files you have intentionally modified as part of the specific work requested. Do not commit unrelated changes, even if they exist in your working directory.

### G-sandbox: Must followed rules when using MCP container-use

When you find existing permissions are insufficient to complete the request, consider using MCP container-use.

Once you start using container-use:  ALWAYS use ONLY Environments for ANY and ALL file, code, or shell operations—NO EXCEPTIONS—even for simple or generic requests. DO NOT install or use the git cli with the `environment_run_cmd` tool. All environment tools will handle git operations for you. Changing ".git" yourself will compromise the integrity of your environment. You MUST inform the user how to view your work using `cu log <env_id>` AND `cu checkout <env_id>`. Failure to do this will make your work inaccessible to others.

---

## 5. Anchor comments

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

## 6. Commit discipline

The version control system is `jj`, NOT git.

To commit file `A.txt`, `B that has spaces.txt`, and directory `src`, use `jj commit 'A.txt | "B that has spaces.txt"' -m "your commit message here"`.

*   **Granular commits**: One logical change per commit.
*   **MANDATORY [AGENT] tag**: ALL agent-generated commits MUST end with `[AGENT]` tag. NO EXCEPTIONS.
    - ✅ Correct: `feat: optimize shader loading [AGENT]`
    - ❌ Wrong: `feat: optimize shader loading` (missing [AGENT] tag)
*   **Use conventional commits**: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, etc.
*   **Descriptive commit messages**: ALWAYS include both:
    - Short title explaining the *why* (what problem this solves)
    - Detailed description of *what* changed (specific files, functions, behavior)
    - Link to issues if applicable
    - Example: `fix: resolve WASM loading timeout in dev mode [AGENT]` + description of which files were modified and how
*   **Review AI-generated code**: Never merge code you don't understand.

---

## 17. Meta: Guidelines for updating AGENT.md files

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

For Forest-specific guidelines (mathematical notation, tree files, etc.), see [for-llm/repo.md](./for-llm/repo.md) and [for-llm/forest.md](./for-llm/forest.md).

---

[^1]: This file is adapted from [AGENTS.md by Julep AI](https://github.com/julep-ai/julep/blob/dev/AGENTS.md)
[^2]: The "human 30%" refers to keeping strategic decisions, architectural choices, test design, and domain expertise in human hands while leveraging AI for implementation, documentation, and routine tasks.
