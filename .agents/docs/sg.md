# ast-grep (sg) Structural Search Guide

This guide helps agents and humans use ast-grep (`sg`) for robust, code-structure-aware search and refactoring in this repository. It covers key ingredients, best practices, reference links, and working examples for both TypeScript and Python.

---

## Key Ingredients for Effective sg Usage

-   **Always use the `rule:` key at the top level** in your YAML rule files, especially if you want to use advanced features like `inside`, `not`, `has`, etc. (see caveats below).
-   **Prefer YAML rule files** for non-trivial, structure-aware patterns (place in `.agents/scripts/sg/`).
-   **Use `kind` for AST node type** (e.g., `function_definition`, `method_definition`).
-   **Add `constraints`** to filter matches by variable names, regex, etc.
-   **Test rules on real files** (e.g., `sg scan .agents/scripts/sg/myrule.yml <target-file>`).
-   **Reference the [ast-grep rule catalog](https://ast-grep.github.io/rule-cookbook/) and [playground](https://play.ast-grep.dev/) for inspiration.**

---

## Reference Links

-   [ast-grep Documentation](https://ast-grep.github.io/docs/)
-   [Rule Cookbook](https://ast-grep.github.io/rule-cookbook/)
-   [Playground](https://play.ast-grep.dev/)
-   [YAML Rule Format](https://ast-grep.github.io/docs/rule-syntax/)
-   [Supported Languages](https://ast-grep.github.io/docs/language-support/)
-   [Extensive ast-grep Guide (appdotbuild/claude_astgrep)](https://raw.githubusercontent.com/appdotbuild/claude_astgrep/refs/heads/main/.claude/commands/ast_grep.md) — Consult this for advanced features (e.g. `inside`, `has`, `all`, `not`, `fix`, `utils`), debugging tricky rules, or language-specific edge cases.
-   `.agents/scripts/sg/` for working rule examples and `test-sg.sh` if you are stuck.

---

## Example: TypeScript Method Match

**Goal:** Match `close(ws) { ... }` method in a `.ws` handler object.

```yaml
id: match-ws-close-method
language: typescript
rule:
    pattern: "close($WS)"
    kind: method_definition
```

> **Note:** This matches all `close` methods, not just `async` ones. As of ast-grep 2025-08, it is not possible to match the `async` modifier with a simple pattern. Use the [ast-grep playground](https://play.ast-grep.dev/) for advanced cases or to experiment with new grammar support.

**Example match (made-up):**

```ts
app.ws("/live", {
    async close(ws) {
        ws.terminate();
    },
    open(ws) {
        // not matched
    },
});
```

---

## Example: Python Function Name Contains "title"

**Goal:** Match any function definition whose name contains "title".

```yaml
id: py-func-title
language: python
rule:
    pattern: "def $NAME($$$ARGS): $$$BODY"
    kind: function_definition
constraints:
    NAME:
        regex: ".*title.*"
```

**Example match (made-up):**

```python
def get_title_case(text):
    return text.title()

def subtitle(text):
    return f"Sub: {text}"

def main():
    pass  # not matched
```

---

## Example: Python Assignment to Variable Named "title"

**Goal:** Match assignments to a variable named `title`.

```yaml
id: py-assign-title
language: python
rule:
    pattern: "title = $VAL"
    kind: expression_statement
```

> **Note:** This only matches assignments to the hardcoded variable `title`. ast-grep currently does not support meta-variables for assignment left-hand sides in Python. Use the [playground](https://play.ast-grep.dev/) to experiment with new grammar support or advanced cases.

**Example match (made-up):**

```python
title = "My Document"
subtitle = "A Subtitle"  # not matched
title = get_title_case(title)
```

---

## Example: TypeScript DOM Event Handler Assignment

**Goal:** Match all assignments of event handlers to DOM elements, e.g., `element.onclick = ...`, `element.onchange = ...`, etc.

```yaml
id: ts-dom-event-handler-assignment
language: typescript
rule:
    pattern: "$OBJ.$EVENT = $VAL"
    kind: expression_statement
constraints:
    EVENT:
        regex: "^on.*"
```

> **Note:** This may not match in all cases due to ast-grep limitations with property assignment parsing or meta-variable support. Use the [playground](https://play.ast-grep.dev/) for advanced or tricky cases.

**Example match (made-up):**

```ts
const button = document.createElement("button");
button.onclick = () => alert("Clicked!");
input.onchange = handleChange;
link.onmouseover = function () {
    /* ... */
};
// Not matched:
button.disabled = true;
```

---

## Workflow for Using sg in This Repo

1. **Write YAML rules** in `.agents/scripts/sg/` for your search/refactor task, there are some examples and `test-sg.sh` for reference if you are stuck. **Always use the `rule:` key at the top level.**
2. **Test rules** on target files:
    ```bash
    sg scan .agents/scripts/sg/myrule.yml <target-file>
    ```
    You can also use `sg scan <rule.yml> <target-file>` for any individual YAML rule file, without needing a project config.
3. **Iterate**: Refine `pattern`, `kind`, and `constraints` as needed.
4. **Document**: Add a comment or docstring to your rule file for clarity.

---

## Tips & Gotchas

-   Use `kind` (not `selector`/`context`) for AST node type (e.g., `function_definition`, `method_definition`).
-   Use `pattern` as a string for code shape (with `$NAME`, `$VAL`, `$$$ARGS`, `$$$BODY` for wildcards).
-   Place `constraints` at the top level (not inside `pattern` or `rule`).
-   Some language grammars (notably Python) have limitations with meta-variables for assignment left-hand sides and certain modifiers (e.g., `async`).
-   **Caveat:** As of 2025-08, advanced features like `inside` and `not` do not always work as expected in single-rule YAML files, even with the correct structure. For example, rules using `inside` to match Python methods inside classes, or `not` to exclude functions with a `return` statement in TypeScript, may not match as intended. This is a known limitation—see [ast-grep discussions](https://github.com/ast-grep/ast-grep/discussions) and [playground](https://play.ast-grep.dev/) for the latest status and workarounds.
-   Use the [playground](https://play.ast-grep.dev/) to prototype rules interactively and test edge cases.
-   For simple text search, use `rg` (ripgrep); for structure, use `sg`.

---

_Last updated: 2025-08-07_
