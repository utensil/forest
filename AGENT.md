# Agent Instructions for Forest

*Last updated 2025-01-06*

> **purpose** – This file is the onboarding manual for every AI assistant (Claude, Cursor, GPT, etc.) and every human who edits this repository.  
> It encodes our coding standards, guard-rails, and workflow tricks so the *human 30 %* (architecture, tests, domain judgment) stays in human hands.

---

## 0. Project overview

Forest is a sophisticated mathematical research environment and Zettelkasten system built using Forester. It serves as a personal knowledge management system for mathematical concepts, technical experiments, and research notes, with over 1300+ commits accumulated since 2024.

The system combines multiple technologies to create a hybrid authoring environment that supports both web-based browsing and traditional academic PDF generation. It integrates Forester (a Zettelkasten note-taking system) with modern development tools, mathematical typesetting, and experimental interactive content.

**Golden rule**: When unsure about implementation details or requirements, ALWAYS consult the developer rather than making assumptions.

---

## 1. Non-negotiable golden rules

| #: | AI *may* do                                                            | AI *must NOT* do                                                                    |
|---|------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| G-0 | Whenever unsure about something that's related to the project, ask the developer for clarification before making changes.    |  ❌ Write changes or use tools when you are not sure about something project specific, or if you don't have context for a particular feature/decision. |
| G-1 | Generate code **only inside** relevant source directories (e.g., `bun/`, `trees/`, `tex/`, `assets/`) or explicitly pointed files.    | ❌ Touch test files, CI configs, or core build scripts without explicit permission. |
| G-2 | Add/update **`FOREST-NOTE:` anchor comments** near non-trivial edited code. | ❌ Delete or mangle existing `FOREST-` comments.                                     |
| G-3 | Follow lint/style configs (`biome.json`, `knip.json`). Use the project's configured linter (Biome), if available, instead of manually re-formatting code. | ❌ Re-format code to any other style.                                               |
| G-4 | For changes >300 LOC or >3 files, **ask for confirmation**.            | ❌ Refactor large modules without human guidance.                                     |
| G-5 | Stay within the current task context. Inform the dev if it'd be better to start afresh.                                  | ❌ Continue work from a prior prompt after "new task" – start a fresh session.      |

---

## 2. Build, test & utility commands

Use `just` tasks for consistency (they ensure correct environment variables and configuration).

```bash
# Development and building
just dev             # Development server with file watching at http://localhost:1314
just build           # Main build command that builds Forest + bun assets
just forest          # Build the forest using forester
just chk             # Biome linting/formatting (--fix in dev, ci mode in CI)

# Single file builds
just js bun/<file>   # Build single JS/TS file
just css bun/<file>  # Build single CSS file

# LaTeX and PDF generation
./lize.sh <tree-id>  # Build LaTeX documents to PDF
just lize            # Build multiple LaTeX documents

# Content management
just new <prefix>    # Create new tree file
just rss-stars       # Process RSS starred items into learning diary
```

For simple, quick checks: `bunx biome check --fix` (ensure correct CWD).

---

## 3. Coding standards

*   **JavaScript/TypeScript**: ES2022+, Bun runtime, `async/await` preferred.
*   **Formatting**: Biome enforces 4-space indents, single quotes, semicolons as needed. Standard Biome linter rules.
*   **Typing**: Enabled where beneficial; focus on maintainability over strict typing.
*   **Naming**: `camelCase` (JS/TS functions/variables), `PascalCase` (components), `kebab-case` (files), `SCREAMING_SNAKE` (constants).
*   **Error Handling**: Graceful degradation; log errors with context.
*   **Documentation**: JSDoc for complex functions; inline comments for complex logic.
*   **Dependencies**: Check `knip.json` for unused dependency detection.

**Error handling patterns**:
- Use try/catch blocks appropriately
- Provide meaningful error messages
- Log errors with sufficient context for debugging
- Gracefully handle missing dependencies (especially WASM modules)

Example:
```javascript
// FOREST-NOTE: WASM modules may fail to load; graceful degradation required
try {
    const wasmModule = await import('./lib/egglog/pkg/egglog.js')
    return wasmModule.processData(input)
} catch (error) {
    console.warn('WASM module unavailable, falling back to simple processing:', error)
    return simpleProcessing(input)
}
```

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

- Use `FOREST-NOTE:`, `FOREST-TODO:`, or `FOREST-QUESTION:` (all-caps prefix) for comments aimed at AI and developers.
- Keep them concise (≤ 120 chars).
- **Important:** Before scanning files, always first try to **locate existing anchors** `FOREST-*` in relevant subdirectories.
- **Update relevant anchors** when modifying associated code.
- **Do not remove `FOREST-NOTE`s** without explicit human instruction.
- Make sure to add relevant anchor comments, whenever a file or piece of code is:
  * too long, or
  * too complex, or
  * very important, or
  * confusing, or
  * could have a bug unrelated to the task you are currently working on.

Example:
```javascript
// FOREST-NOTE: perf-hot-path; WASM loading can be slow on first run
async function loadEgglogWasm() {
    ...
}
```

---

## 6. Commit discipline

*   **Granular commits**: One logical change per commit.
*   **Tag AI-generated commits**: e.g., `feat: optimize shader loading [AI]`.
*   **Clear commit messages**: Explain the *why*; link to issues if architectural.
*   **Use conventional commits**: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, etc.
*   **Review AI-generated code**: Never merge code you don't understand.

---

## 7. 🌲 Forester content & tree files

*   To modify tree content, **edit `.tree` files** in `trees/`.
*   **Follow Forester syntax**: Use `\import{macros}`, `\taxon{type}`, `\tag{topic}` for organization.
*   **Mathematical content**: Use `\refcardt{type}{name}{tag}{ref}{}` for theorems, definitions, etc.
*   **Address format**: Use `xxx-NNNN` where `xxx` is prefix (uts, ag, tt, ca, spin, hopf) and `NNNN` is base-36 number.
*   **Content structure**: Wrap paragraphs in `\p{}`, use proper mathematical notation.

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

*   Learning diary entries use `\mdblock{YYYY-MM-DD}{}` format.
*   Process RSS starred items: `just rss-stars` generates JSON data for integration.
*   Entries are sorted by arrival date (newest first).
*   Use consistent link formats: `[Title](URL)` for web resources, `\citek{ref-id}` for citations.
*   Group related items under topic headers when multiple entries exist.

**Learning diary example**:
```forester
\mdblock{2025-01-06}{
- Math
    - found [Category Theory Illustrated](https://example.com/ct-illustrated)
    - read \citek{maclane1971categories}
- ML
    - found [Attention is All You Need](https://arxiv.org/abs/1706.03762)
}
```

---

## 9. 🌲 Build system & dependencies

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

---

## 10. 🌲 Mathematical notation & macros

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

## 11. Common pitfalls

*   Forgetting to import `macros.tree` in new tree files.
*   Using incorrect Forester syntax (missing `\p{}` around paragraphs).
*   Not following tree file naming conventions (xxx-NNNN format).
*   Mixing different quotation styles in JavaScript (use single quotes).
*   Not handling WASM module loading failures gracefully.
*   Editing generated files instead of source files.
*   Large refactors without considering build dependencies.

---

## 12. 🌲 Domain-Specific Terminology

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

## 13. Key File & Pattern References

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

## 14. Meta: Guidelines for updating AGENT.md files

This file should be updated when:
- New major features or tools are added to the project
- Build processes or development workflows change significantly  
- New coding standards or conventions are established
- Common pitfalls or debugging patterns are identified
- Domain-specific terminology evolves

The 🌲 marker indicates sections specific to the Forest project, while unmarked sections contain general best practices applicable to similar projects.
