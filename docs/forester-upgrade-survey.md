# Forester 5.x Upgrade Survey

**Date:** 2026-05-03
**Current pinned commit:** `56de06afe952d752c1a13fdcd8bb56c5fef9956f`
**Latest HEAD (main):** `5ab7277`
**Total commits between:** 592

## Summary of Major Changes

| Category | Count | Risk |
|----------|-------|------|
| Breaking changes (syntax/output) | ~15 | HIGH |
| Bug fixes relevant to issue #9 | ~8 | LOW (positive) |
| Internal refactoring | ~400+ | LOW |
| New features (LSP, datalog, HTMX) | ~50 | MEDIUM |
| Performance improvements | ~20 | LOW |

## Breaking Changes (HIGH IMPACT)

### 1. Namespace Change
**Commit:** `7ba99ae update forester xmlns`
- **Change:** Namespace changed from `http://www.jonmsterling.com/jms-005P.xml` to `http://www.forester-notes.org`
- **Impact:** All XSL files referencing the old namespace
- **Status:** ALREADY FIXED in our XSL files (phases 1-3)

### 2. Subdirectories and Base URLs in Output
**Commit:** `54fa7e2 Subdirectories and base URLs in output (breaking change)`
- **Change:** Output structure changed from `output/TREE.xml` to `output/forest/TREE/index.xml`
- **Impact:** `lize.sh`, `convert_xml.sh`, any scripts referencing old paths
- **Status:** ALREADY FIXED in lize.sh (phase 3)

### 3. HTML Elements for Basic Content
**Commits:** `9a39be7 Defer to HTML in IR for basic things like p, em, etc.` + `6a36627 Legacy_xml_renderer: send basic things like p,em,etc. to HTML`
- **Change:** `f:p`, `f:em`, `f:strong`, `f:ol`, `f:ul`, `f:li`, `f:code` → `html:p`, `html:em`, etc.
- **Impact:** LaTeX XSL pipeline (article.xsl, latex.xsl)
- **Status:** ALREADY FIXED (phase 3)

### 4. Remove Built-in Img Node
**Commit:** `69b88ca Remove built-in Img node (use html!)`
- **Change:** `f:img` no longer exists, use `html:img` instead
- **Impact:** Any XSL template matching `f:img`
- **Status:** Our `uts-overrides.xsl` has `fr:img[@src]` template — needs verification

### 5. Remove Anchors Entirely
**Commit:** `e30b0b4 Legacy_xml_client: Remove anchors entirely`
- **Change:** `fr:anchor` element removed from output; use `generate-id()` instead
- **Impact:** TOC generation, in-page links
- **Status:** ALREADY FIXED (commit `3290e59d` on main)

### 6. Remove Config.prefixes
**Commit:** `d370daf Remove Config.prefixes now`
- **Change:** The `prefixes` config field in `forest.toml` no longer works
- **Impact:** Our `forest.toml` already has it commented out — NO IMPACT

### 7. Remove Legacy Query Engine
**Commit:** `61f5d25 remove legacy query engine`
- **Change:** Old `\query` syntax removed, replaced by datalog queries
- **Impact:** Trees using `\query/root`, `\rel/links-to/reflexive-transitive-closure`, etc.
- **Status:** This is Phase 5 (deferred). The `\rel/links-to/reflexive-transitive-closure` is the last missing piece.

### 8. Remove "forester serve"
**Commit:** `2a3f685 Remove "forester serve"`
- **Change:** The `forester serve` command is gone
- **Impact:** Development workflow — need to use separate HTTP server
- **Status:** We already use `python3 -m http.server` — NO IMPACT

### 9. Remove JavaScript Stuff
**Commit:** `b732ed9 Remove JavaScript stuff for now`
- **Change:** Built-in JS (forester.js, ninja-keys) no longer bundled by forester
- **Impact:** Must supply own JS in theme/output
- **Status:** We already provide our own (`uts-forester.js`, `uts-ondemand.js`) — VERIFY theme provides `forester.js`

### 10. Remove renderer.theme Configuration
**Commit:** `e247ad4 Remove renderer.theme configuration: just require it to be in 'theme'`
- **Change:** Theme must be in a directory called `theme` (hardcoded)
- **Impact:** Our `forest.toml` already has `# theme = "theme"` commented out — the default is used
- **Status:** LOW RISK — already compliant

### 11. Remove Frontmatter Overrides
**Commit:** `cc0a980 remove frontmatter overrides feature entirely?`
- **Change:** Can no longer override title/taxon during transclusion
- **Impact:** Any trees that used transclusion title overrides
- **Status:** ALREADY FIXED per issue #9 checklist (commit `861c141`)

### 12. Rename forest.root to forest.home
**Commit:** `1e461fb Rename forest.root to forest.home; fix some logic`
- **Change:** Config field renamed
- **Impact:** Our `forest.toml` already uses `home = "index"` — NO IMPACT

### 13. [Breaking] Improve sorting of trees, change format of json manifest
**Commit:** `1eb944d`
- **Change:** JSON manifest format changed
- **Impact:** Any tooling reading the JSON manifest
- **Status:** LOW RISK unless we consume the manifest

### 14. Contextual Numbers Replace f:ref
**Commit:** `7b6bfcd add Contextual_number`
- **Change:** `f:ref` replaced by `fr:link` containing `fr:contextual-number`
- **Impact:** LaTeX XSL cross-reference handling
- **Status:** ALREADY HANDLED (phase 3 — added suppression template)

### 15. Addr → Display-URI
**Commits:** Multiple (part of IRI/URI refactoring: `74f9331 The Great IRI => URI Renaming`)
- **Change:** `f:addr` → `fr:display-uri`, `@addr` → `@display-uri` on links
- **Impact:** All XSL templates referencing addr
- **Status:** ALREADY FIXED (phase 3)

## Bug Fixes Relevant to Issue #9

### Fixed upstream (should resolve with bump):

| Issue | Commit | Description |
|-------|--------|-------------|
| #188 (`#` in `#abc` removed) | `63fbae6` | Fix compiler expansion for hashtag-like strings |
| #179 (broken link false warnings) | `424f33d` | Don't emit broken link warning from inside backmatter |
| Whitespace/text | `a05feb0` | Concatenate text nodes as they are emitted |
| URL queries stripped | `4b96011` | Don't accidentally strip out URL queries |
| `\%` lexing | `f364375` | fix lexing of \% |
| xmlns in HTML | `217905b` | strip html xmlns in html renderer |

### NOT clearly fixed upstream:

| Issue | Status |
|-------|--------|
| #180 (internal_error: Cannot render content as TeX) | Unclear — may be fixed by refactoring |
| #182 (XML expansion treats args inconsistently) | Not explicitly fixed in commit messages |
| #187 (meta data not accessible for custom functions) | Not explicitly fixed in commit messages |

## New Features (may affect us)

### Datalog Query System
**Commits:** `dab0829 Add support for datalog` and many following
- Replaces the old query engine
- New relations: `is-asset`, `is-article`, `in-host`
- Relevant for Phase 5 (query syntax migration)

### LSP (Language Server Protocol)
- Extensive LSP development (completions, hover, symbols, diagnostics)
- Positive for development experience

### HTMX Client (experimental)
- New server-rendered frontend approach
- We don't use it — no impact

### Content-Addressed Assets
**Commit:** `6dfc075 content addressing assets`
- Assets are now content-addressed (hash-based names)
- We already see this pattern (SVG resources use hashes)

## Risk Assessment

### LOW RISK (already handled):
- Namespace change ✓
- Output path structure ✓
- HTML element migration ✓
- Anchor removal ✓
- Addr → display-uri ✓
- Config field renames ✓

### MEDIUM RISK (needs verification after bump):
- `fr:img` template in `uts-overrides.xsl`
- `forester.js` / theme JS availability
- Broken link warning behavior
- Build error messages (new diagnostic system)
- OCaml 5.3 requirement for building from source

### HIGH RISK (Phase 5, deferred):
- Datalog query migration (`\rel/links-to/reflexive-transitive-closure`)
- Any remaining old query syntax

## Recommended Migration Steps

1. **Pre-bump verification:**
   - Ensure OCaml 5.3+ is available (required by newer forester)
   - Back up current working state

2. **Bump target:** Latest HEAD (`5ab7277`) or most recent tagged release
   - Note: There are no tags after our pin — HEAD is the "latest stable"

3. **After bump, verify:**
   - [ ] `forester build` succeeds without new errors
   - [ ] Warning count hasn't dramatically increased
   - [ ] `./build.sh` completes (full XML→HTML pipeline)
   - [ ] `./lize.sh tt-0001` still generates PDF
   - [ ] `fr:img` template still works (check embedded SVG rendering)
   - [ ] `forester.js` is in theme/ and gets copied to output
   - [ ] Broken link warnings are reasonable (not false positives)

4. **If issues arise:**
   - Check for `\query` syntax that needs datalog migration
   - Check for `fr:img` → `html:img` migration needs
   - Verify theme files are complete

## OCaml/Build Requirements

The latest forester requires:
- OCaml 5.3+ (commit `156ad98 Require OCaml 5.3`)
- Removed dependencies: ppx_blob, quicheck
- Reformatted with topiary (then later ocamlformat)
- Static build support via nix

Our `prep.sh` uses `opam pin` which should handle deps, but OCaml 5.3 may need a switch upgrade.
