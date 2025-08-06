# ast-grep (sg) Structural Search Guide

This guide helps agents and humans use ast-grep (`sg`) for robust, code-structure-aware search and refactoring in this repository. It covers key ingredients, best practices, reference links, and working examples for both TypeScript and Python.

---

## Key Ingredients for Effective sg Usage

-   **Prefer YAML rule files** for non-trivial, structure-aware patterns (place in `.agents/scripts/sg/`).
-   **Use `selector` and `context`** to match AST nodes and code structure, not just text.
-   **Add `constraints`** to filter matches by variable names, regex, etc.
-   **Test rules on real files** (e.g., `sg -r .agents/scripts/sg/myrule.yml <target-file>`).
-   **Reference the [ast-grep rule catalog](https://ast-grep.github.io/rule-cookbook/) and [playground](https://play.ast-grep.dev/) for inspiration.**

---

## Reference Links

-   [ast-grep Documentation](https://ast-grep.github.io/docs/)
-   [Rule Cookbook](https://ast-grep.github.io/rule-cookbook/)
-   [Playground](https://play.ast-grep.dev/)
-   [YAML Rule Format](https://ast-grep.github.io/docs/rule-syntax/)
-   [Supported Languages](https://ast-grep.github.io/docs/language-support/)
-   [Extensive ast-grep Guide (appdotbuild/claude_astgrep)](https://raw.githubusercontent.com/appdotbuild/claude_astgrep/refs/heads/main/.claude/commands/ast_grep.md) — Consult this for advanced features (e.g. `inside`, `has`, `all`, `not`, `fix`, `utils`), debugging tricky rules, or language-specific edge cases.

---

## Example: TypeScript Method Match

**Goal:** Match `async close(ws) { ... }` method in a `.ws` handler object.

```yaml
id: match-ws-close-method
language: typescript
message: "Matches async close(ws) method in .ws handler object."
severity: info
rule:
    pattern:
        context: |
            .ws('/live', {
              async close(ws) {
                $$$BODY
              }
            })
        selector: method_definition
```

---

## Example: Python Function Name Contains "title"

**Goal:** Match any function definition whose name contains "title".

```yaml
id: py-func-title
language: python
message: "Function definition with 'title' in name"
severity: info
rule:
    pattern:
        selector: function_definition
        context: "def $NAME($$$ARGS): $$$BODY"
constraints:
    NAME:
        regex: ".*title.*"
```

---

## Example: Python Assignment to Variable Named "title"

**Goal:** Match assignments to a variable named `title`.

```yaml
id: py-assign-title
language: python
message: "Assignment to variable named 'title'"
severity: info
rule:
    pattern:
        selector: expression_statement
        context: "$NAME = $VAL"
constraints:
    NAME:
        regex: "title"
```

---

## Workflow for Using sg in This Repo

1. **Write YAML rules** in `.agents/scripts/sg/` for your search/refactor task.
2. **Test rules** on target files:
    ```bash
    sg -r .agents/scripts/sg/myrule.yml <target-file>
    ```
3. **Iterate**: Refine `selector`, `context`, and `constraints` as needed.
4. **Document**: Add a comment or docstring to your rule file for clarity.

---

## Tips & Gotchas

-   Use `selector` for AST node type (e.g., `function_definition`, `method_definition`).
-   Use `context` for code shape (with `$NAME`, `$VAL`, `$$$ARGS`, `$$$BODY` for wildcards).
-   Place `constraints` at the top level (not inside `pattern`).
-   Use the [playground](https://play.ast-grep.dev/) to prototype rules interactively.
-   For simple text search, use `rg` (ripgrep); for structure, use `sg`.

---

## See Also

-   `.agents/scripts/sg/` for working rule examples
-   [ast-grep official docs](https://ast-grep.github.io/docs/)

---

_Last updated: 2025-08-06_
