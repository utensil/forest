# Agent Instructions for Forest

## Build/Lint/Test Commands
- **Build**: `./build.sh` or `just build` - Main build command that builds Forest + bun assets
- **Dev**: `./dev.sh` or `just dev` - Development server with file watching at http://localhost:1314
- **Lint**: `./chk.sh` or `just chk` - Biome linting/formatting (--fix in dev, ci mode in CI)
- **Forest Build**: `just forest` - Build the forest using forester
- **LaTeX Build**: `./lize.sh <tree-id>` or `just lize` - Build LaTeX documents to PDF
- **Single JS Build**: `just js bun/<file>` - Build single JS/TS file
- **Single CSS Build**: `just css bun/<file>` - Build single CSS file

## Architecture
- **Forest**: A Zettelkasten-style mathematical research environment using Forester
- **Main Content**: `.tree` files in `trees/` (500+ mathematical notes with prefixes: uts, ag, tt, ca, spin, hopf)
- **Content Types**: Category theory, Clifford algebras, spin groups, algebraic geometry, type theory
- **Assets**: CSS/JS/WASM in `bun/`, LaTeX templates in `tex/`, shaders in `assets/shader/`
- **Output**: Multi-format output (web + PDF) in `output/` directory served at port 1314
- **Build Tools**: Bun for JS/TS, Lightning CSS for CSS, Forester for tree files, LaTeX for PDFs
- **WASM Integration**: Custom WASM modules for egglog, wgputoy, rhaiscript cloned to `lib/`
- **AI Integration**: Comprehensive LLM toolchain with aider, goose, and other AI assistants

## Forester Content Format
- **Tree Files**: Use `.tree` extension with unique addresses `xxx-NNNN` (prefix + base-36 number)
- **Structure**: Start with `\import{macros}`, use `\taxon{type}`, `\tag{topic}` for organization
- **Content**: Wrap paragraphs in `\p{}`, use `\refcardt{type}{name}{tag}{ref}{}` for math content
- **References**: Internal links `[text](tree-id)`, citations `\citek{ref-id}`, external `\link{url}`
- **Math**: Inline `#{math}`, display `##{math}`, equations `\eqtag{id}{content}`
- **Learning Diary**: Use `\mdblock{YYYY-MM-DD}{}` format, newest first, process RSS with `just rss-stars`

## Code Style
- **JS/TS Formatting**: 4-space indents, single quotes, semicolons as needed (Biome)
- **Import Organization**: Enabled via Biome
- **Files**: Include `bun/**/*`, `dev.ts`, `*.config.js`, `permlink.js`
- **Linting**: Biome recommended rules, `noNonNullAssertion` disabled
- **Dependencies**: Check `knip.json` for unused dependency detection
