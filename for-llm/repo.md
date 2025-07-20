# Repository-Specific Guidelines for Forest

*Last updated 2025-07-20*

## 1. Project overview

Forest is a sophisticated mathematical and technical research environment and Zettelkasten system built using Forester. It serves as a personal knowledge management system for mathematical concepts, technical experiments, and research notes, with over 1300+ commits accumulated since 2024.

The system combines multiple technologies to create a hybrid authoring environment that supports both web-based browsing and traditional academic PDF generation. It integrates Forester (a Zettelkasten note-taking system) with modern development tools, mathematical typesetting, and experimental interactive content.

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

*   **No formal unit testing framework**: This project focuses on mathematical content and documentation rather than traditional software testing.
*   **Validation approaches**: Build verification, link checking, LaTeX compilation, and custom validation scripts serve as the testing methodology.
*   **Content validation**: Ensure tree files have proper Forester syntax.
*   **Manual testing**: Preview changes in development server before committing.
*   **Verification scripts**: Create validation scripts under `.agents/` to verify changes work correctly.

**Validation commands**:
```bash
just chk            # Lint JavaScript/TypeScript files
just build          # Full build validation
```

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

## 5. 🌲 Forester content & tree files

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

## 6. 🌲 Learning Diary & RSS Integration

See `for-llm/learning_diary.md` for comprehensive documentation on learning diary format, RSS processing, and integration patterns.

Key points:
*   Learning diary entries use `\mdblock{YYYY-MM-DD}{}` format
*   Process RSS starred items: `just stars` generates JSON data for integration
*   Entries are sorted by arrival date (newest first)
*   Use consistent link formats: `[Title](URL)` for web resources, `\citef{ref-id}` for citations (shows full title)
*   Group related items under topic headers when multiple entries exist
*   Use hierarchical organization with year and month subtrees

## 7. 🌲 Mathematical notation & macros

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

## 8. Common pitfalls

*   Forgetting to import `macros.tree` in new tree files.
*   Using incorrect Forester syntax (missing `\p{}` around paragraphs).
*   Not following tree file naming conventions (xxx-NNNN format).
*   Mixing different quotation styles in JavaScript (use single quotes).
*   Not handling WASM module loading failures gracefully.
*   Editing generated files instead of source files.
*   Large refactors without considering build dependencies.

## 9. 🌲 Domain-Specific Terminology

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

## 10. Key File & Pattern References

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

## 11. Directory-Specific documentation

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

## 12. Versioning & deployment

*   **No formal versioning**: Content-focused repository with continuous integration.
*   **Deployment**: Automatic GitHub Pages deployment on main branch push.
*   **Git workflow**: Direct commits to main for content, feature branches for major changes.
*   **Backup strategy**: Git history serves as version control and backup.

## 13. Performance considerations

*   **WASM loading**: First-time WASM module loading can be slow; implement graceful degradation.
*   **Build optimization**: Use file watching in development to avoid full rebuilds.
*   **Asset optimization**: Lightning CSS and Bun handle minification and bundling.
*   **PDF generation**: LaTeX compilation is resource-intensive; run only when needed.
