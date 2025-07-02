# Agent Instructions for Forest

*Last updated 2025-07-02*

> **Purpose** – This file is the onboarding manual[^1] for every AI assistant (Claude, Amp, Codex, Amazon Q, OpenCode etc.) and every human who edits this repository.
> It encodes our coding standards, guard-rails, and workflow tricks so the *human 30 %*[^2] (architecture, tests, domain judgment) stays in human hands.

---

## 0. Non-negotiable GOLDEN rules

ALWAYS cite the rules which you are following at the end of your reply, like this: "(per G-ask, G-verify)".

### G-ask: Always ask for clarification when unsure
- ✅ **Should**: Ask the developer for clarification before making changes when unsure about project-specific details or lacking context for a particular feature/decision
 - ❌ **Must NOT**: make assumptions, write changes or use tools when uncertain

### G-scope: Stay within designated code areas  
- ✅ **May**: Generate code only inside relevant source directories or explicitly pointed files
- ❌ **Must NOT**: Touch test files, CI configs, or core build scripts without explicit permission

### G-note: Use anchor comments appropriately
- ✅ **May**: Add/update `AGENT-NOTE:` anchor comments (see section "Anchor comments" below) near non-trivial edited code
- ❌ **Must NOT**: Delete or mangle existing `AGENT-*` comments

### G-lint: Follow project linting and style
- ✅ **May**: Follow section "Coding standards" below, and lint/style configs using the configured linters
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

- ✅ **Should**: Verify your changes by learning how the code is supposed to run/test/lint (see also section "Build, test & utility commands" below), then design a way to verify. Prefer to re-use or add tests to verify. If you need temporary script or mock data to do so, keep them all under `.agents/`, and don't remove them afterward.
- ❌ **Must NOT**: Run scripts or commands that contains dangerous code, or unrelated to code exploration and change verification.

### G-commit: Commit your changes to git

- ✅ **Should**: Before editing files, commit those files to git if they are not committed. After editing files, before pausing and asking for further instructions, commit your changes to git. ALWAYS commit per section "Commit discipline" below.
- ❌ **Must NOT**: Commit files that are not changed or going to be changed by you.

### G-sandbox: Must followed rules when using MCP container-use

When you find existing permissions are insufficient to complete the request, consider using MCP container-use.

Once you start using container-use:  ALWAYS use ONLY Environments for ANY and ALL file, code, or shell operations—NO EXCEPTIONS—even for simple or generic requests. DO NOT install or use the git cli with the `environment_run_cmd` tool. All environment tools will handle git operations for you. Changing ".git" yourself will compromise the integrity of your environment. You MUST inform the user how to view your work using `cu log <env_id>` AND `cu checkout <env_id>`. Failure to do this will make your work inaccessible to others.

---

## 1. Project overview

Forest is a sophisticated mathematical and technical research environment and Zettelkasten system built using Forester. It serves as a personal knowledge management system for mathematical concepts, technical experiments, and research notes, with over 1300+ commits accumulated since 2024.

The system combines multiple technologies to create a hybrid authoring environment that supports both web-based browsing and traditional academic PDF generation. It integrates Forester (a Zettelkasten note-taking system) with modern development tools, mathematical typesetting, and experimental interactive content.


---

## 2. Build, test & utility commands

Use `just` tasks for consistency (they ensure correct environment variables and configuration).

### Core build commands

```bash
# Development and building
just dev             # Development server with file watching at http://localhost:1314 , agents should assume that this is already running by human, and should not run it, but may access it via http
just build           # Main build command that builds Forest + bun assets, agents could use this to verify build result and gather feedback
just chk             # Biome linting/formatting, agents should usually run `just chk` after modifying css, js files, if it failed with unsafe changes, agensts may even run `bunx biome check --fix --unsafe` after reviewing the unsafe changes

# Single file builds, discover more similar tasks from `build_changed.sh` for various file types
just js <file>   # Build single JS/TS file
just css <file>  # Build single CSS file

# LaTeX and PDF generation
./lize.sh <tree-id>  # Build LaTeX documents to PDF
just lize            # Build multiple LaTeX documents

# Content management
just new <prefix>    # Create new tree file, agents should use this to create a new tree, to ensure the format follows the conventions for the trees with the same prefix
just stars           # Process RSS starred items into learning diary
```

### Build system & dependencies

*   **Bun**: Primary JavaScript/TypeScript runtime and package manager.
*   **Biome**: Linting and formatting (configured in `biome.json`).
*   **Lightning CSS**: CSS processing and bundling.
*   **Forester**: Tree file processing and site generation.
*   **WASM modules**: Custom modules cloned to `lib/` directory, built with `wasm-pack`.
*   **LaTeX**: PDF generation using custom templates in `tex/`.

**Build process**:
1. `just dev` starts development server with file watching
2. Changes to `.tree` files trigger Forester rebuild
3. Changes to `bun/` files trigger JavaScript/CSS rebuilding
4. WASM modules are built in CI or when `UTS_DEV` environment variable is set

### Testing & validation

*   **No formal testing framework**: This project focuses on mathematical content and documentation.
*   **Validation approaches**: Build verification, link checking, LaTeX compilation.
*   **Content validation**: Ensure tree files have proper Forester syntax.
*   **Manual testing**: Preview changes in development server before committing.

**Validation commands**:
```bash
just chk            # Lint JavaScript/TypeScript files
just build          # Full build validation
```

---

## 3. Coding standards

*   **JavaScript/TypeScript**: ES2022+, Bun runtime, `async/await` preferred.
*   **Formatting**: Biome enforces 4-space indents, single quotes, semicolons as needed. Standard Biome linter rules.
*   **Typing**: Enabled where beneficial; focus on maintainability over strict typing.
*   **Naming**: `camelCase` (JS/TS functions/variables), `PascalCase` (components), `kebab-case` (files), `SCREAMING_SNAKE` (constants).
*   **Error Handling**: Graceful degradation; log errors with context.
*   **Documentation**: JSDoc for complex functions; inline comments for complex logic.

**Error handling patterns**:
- Use try/catch blocks appropriately
- Provide meaningful error messages
- Log errors with sufficient context for debugging
- Gracefully handle missing dependencies (especially WASM modules)

---

## 4. Project layout & Core Components

| Directory               | Description                                       |
| ----------------------- | ------------------------------------------------- |
| `trees/`                | 🌲 Forester tree files (500+ mathematical notes) |
| `bun/`                  | JavaScript/TypeScript source files              |
| `assets/`               | Static assets (shaders, XSL templates)          |
| `tex/`                  | 🌲 LaTeX templates and preambles                |
| `output/`               | Generated website and PDF files                 |
| `lib/`                  | External WASM modules (egglog, wgputoy, etc.)   |
| `theme/`                | Forester theme files                             |
| `build/`                | Build artifacts and logs                         |
| `dotfiles/`             | Development environment configurations           |
| `for-llm/`              | 🌲 Documentation for AI assistants              |

**Key domain models** 🌲:
- **Tree Files**: Mathematical notes with unique addresses (xxx-NNNN format)
- **Mathematical Content**: Category theory, Clifford algebras, spin groups, algebraic geometry
- **Learning Diary**: Time-based entries with RSS feed integration
- **References**: Citation management and bibliography
- **Interactive Components**: WASM-based computational tools

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

*   **Granular commits**: One logical change per commit.
*   **Tag agent-generated commits**: e.g., `feat: optimize shader loading [AGENT]`.
*   **Use conventional commits**: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, etc.
*   **Clear commit messages**: a short message explaining the *why* with a longer summary of the changes; link to issues if applicable.
*   **Review AI-generated code**: Never merge code you don't understand.

---

## 7. 🌲 Forester content & tree files

*   To modify tree content, **edit `.tree` files** in `trees/`.
*   **Follow Forester syntax**: Use `\import{macros}`, `\taxon{type}`, `\tag{topic}` for organization.
*   **Mathematical content**: Use `\refcardt{type}{name}{tag}{ref}{}` for theorems, definitions, etc. To learn more about such macros, check `trees/macros.tree`, and `trees/*-macros.tree` files.
*   **Address format**: Use `xxx-NNNN` where `xxx` is prefix (uts, ag, tt, ca, spin, hopf) and `NNNN` is base-36 number.
*   **Content structure**: Wrap paragraphs in `\p{}`, use proper mathematical notation.
*   **Citation formats**: 
    - `\citef{ref-id}` in learning diary (shows full paper title)
    - `\citek{ref-id}` in mathematical content (cites whole papers/books)
    - `\citet{section}{ref-id}` in mathematical content (cites specific sections/theorems)

**Tree file pattern example**:
```forester
\import{macros}
\taxon{definition}
\tag{category-theory}

\title{Category Definition}

\p{A \strong{category} #{C} consists of:}

\ol{
  \li{A collection of objects #{\Ob(C)}}
  \li{A collection of morphisms #{\Mor(C)}}
  \li{Composition operation...}
}

\refcardt{definition}{category}{category-theory}{maclane1971}{
  \p{Formal definition of a category...}
}
```

---

## 8. 🌲 Learning Diary & RSS Integration

See `for-llm/learning_diary.md` for comprehensive documentation on learning diary format, RSS processing, and integration patterns.

Key points:
*   Learning diary entries use `\mdblock{YYYY-MM-DD}{}` format
*   Process RSS starred items: `just stars` generates JSON data for integration
*   Entries are sorted by arrival date (newest first)
*   Use consistent link formats: `[Title](URL)` for web resources, `\citef{ref-id}` for citations (shows full title)
*   Group related items under topic headers when multiple entries exist
*   Use hierarchical organization with year and month subtrees



---

## 9. 🌲 Mathematical notation & macros

*   **Inline math**: `#{math expression}`
*   **Display math**: `##{math expression}`
*   **Equations**: `\eqtag{id}{equation}` for numbered equations
*   **Category theory**: Use predefined macros for common symbols (`\Cat`, `\Set`, `\Mor`, etc.)
*   **String diagrams**: Use category theory macro system for building diagrams
*   **TikZ diagrams**: `\tikzfig{}` blocks for complex mathematical diagrams

**Mathematical content guidelines**:
- Import `macros.tree` at the start of mathematical files
- Use `\refcardt{}` for formal mathematical statements
- Include proofs in `\proof{}` blocks
- Use proper mathematical typography and spacing

---

## 10. Common pitfalls

*   Forgetting to import `macros.tree` in new tree files.
*   Using incorrect Forester syntax (missing `\p{}` around paragraphs).
*   Not following tree file naming conventions (xxx-NNNN format).
*   Mixing different quotation styles in JavaScript (use single quotes).
*   Not handling WASM module loading failures gracefully.
*   Editing generated files instead of source files.
*   Large refactors without considering build dependencies.

---

## 11. 🌲 Domain-Specific Terminology

*   **Tree**: A single note file in Forester format (`.tree` extension).
*   **Forest**: The collection of all trees and their interconnections.
*   **Taxon**: Document type classification (`definition`, `theorem`, `lemma`, etc.).
*   **Tag**: Topic classification for organizing content by subject area.
*   **Address**: Unique identifier for tree files (format: `prefix-NNNN`).
*   **Transclusion**: Including content from one tree within another.
*   **Macro**: Reusable Forester commands and mathematical notation.
*   **WASM**: WebAssembly modules for computational features (egglog, wgputoy, etc.).
*   **Learning Diary**: Time-based entries documenting research and learning progress.
*   **Just**: Task runner used for build commands and development workflows.
*   **Biome**: JavaScript/TypeScript linting and formatting tool.
*   **Lightning CSS**: CSS processing and bundling tool.

---

## 12. Key File & Pattern References

This section provides pointers to important files and common patterns within the codebase.

*   **Tree File Examples**:
    *   Location: `trees/uts-*.tree`, `trees/ag-*.tree`, etc.
    *   Pattern: Forester markup with mathematical content, proper imports and taxonomy.
*   **Mathematical Macros**:
    *   Location: `trees/macros.tree`, `trees/*-macros.tree`
    *   Pattern: Reusable Forester commands and mathematical notation definitions.
*   **Build Scripts**:
    *   Location: `build.sh`, `dev.sh`, `chk.sh`
    *   Pattern: Shell scripts orchestrating multiple build tools.
*   **JavaScript Components**:
    *   Location: `bun/*.{js,ts,jsx,tsx}`
    *   Pattern: Modern JavaScript/TypeScript with WASM integration.
*   **Development Configuration**:
    *   Location: `justfile`, `biome.json`, `package.json`
    *   Pattern: Centralized configuration for development tools.



---

## 13. Directory-Specific documentation

*   **Always check existing patterns** in directories before adding new content.
*   **Follow naming conventions** established in each subject area (uts, ag, tt, ca, spin, hopf).
*   **Mathematical topics** should follow academic conventions and cite sources properly.
*   **Update macro files** when introducing new notation or symbols.

**Subject-specific guidelines**:
- **uts**: General mathematical notes and learning diary
- **ag**: Algebraic geometry concepts and constructions  
- **tt**: Type theory and categorical logic
- **ca**: Category theory fundamentals
- **spin**: Clifford algebras and spin groups
- **hopf**: Hopf algebras and quantum groups

---

## 14. Versioning & deployment

*   **No formal versioning**: Content-focused repository with continuous integration.
*   **Deployment**: Automatic GitHub Pages deployment on main branch push.
*   **Git workflow**: Direct commits to main for content, feature branches for major changes.
*   **Backup strategy**: Git history serves as version control and backup.

---

## 15. Performance considerations

*   **WASM loading**: First-time WASM module loading can be slow; implement graceful degradation.
*   **Build optimization**: Use file watching in development to avoid full rebuilds.
*   **Asset optimization**: Lightning CSS and Bun handle minification and bundling.
*   **PDF generation**: LaTeX compilation is resource-intensive; run only when needed.

---

## 16. 🌲 Writing task automation scripts

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

This script processes NetNewsWire starred items and converts them into
Forester learning diary format with proper date grouping and link formatting.

Usage: just stars (calls this script internally)
"""
```

**Critical functionality documentation:**
```python
# AGENT-NOTE: CRITICAL FEATURES TO MAINTAIN
# 1. IDEMPOTENT: Multiple runs must produce identical results
# 2. ERROR HANDLING: Graceful degradation for missing data
# 3. BUILD INTEGRATION: Validates Forester syntax after processing
# 4. DETERMINISTIC: Sorted processing ensures consistent output
```

### Implementation Patterns

Scripts should handle input/output gracefully, integrate with existing project formats (Forester syntax, bibliography files), and maintain deterministic behavior for consistent results across multiple runs.

### Integration Guidelines

- **Never clean up scripts** - leave them for human inspection and debugging
- Scripts should integrate with `just` commands for consistency
- Include validation commands to verify output correctness
- Add reset/undo functionality for reversible operations
- Use project-specific file paths and naming conventions

### Testing Requirements

Scripts should be designed for:
- **Idempotency testing**: Run twice, second run should show no changes
- **Build validation**: Always verify output doesn't break Forester syntax
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

For Forest-specific guidelines (mathematical notation, tree files, etc.), see [for-llm/forest.md](./for-llm/forest.md).

---

[^1]: This file is adapted from [AGENTS.md by Julep AI](https://github.com/julep-ai/julep/blob/dev/AGENTS.md)
[^2]: The "human 30%" refers to keeping strategic decisions, architectural choices, test design, and domain expertise in human hands while leveraging AI for implementation, documentation, and routine tasks.
