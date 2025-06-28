# Forest-Specific Documentation

*Last updated 2025-06-28*

> **Purpose**: This file contains all Forester-specific guidelines for the Forest repository, including syntax, workflows, and mathematical notation. It complements the general rules in [AGENTS.md](../AGENTS.md).

---

## 1. Forester Content & Tree Files

- **Tree Files**: Edit `.tree` files in `trees/` using Forester syntax.
- **Address Format**: Use `xxx-NNNN` (e.g., `uts-0001`).
- **Key Macros**:
  - `\import{macros}` (required)
  - `\taxon{type}` (e.g., `definition`, `theorem`)
  - `\tag{topic}` (e.g., `category-theory`)
  - `\refcardt{type}{name}{tag}{ref}{}` (for theorems/definitions)

**Example Tree File**:
```forester
\import{macros}
\taxon{definition}
\tag{category-theory}
\title{Category Definition}
\p{A \strong{category} #{C} consists of...}
```

---

## 2. Mathematical Notation

- **Inline Math**: `#{expression}`
- **Display Math**: `##{expression}`
- **Equations**: `\eqtag{id}{equation}`
- **Common Macros**: `\Cat`, `\Set`, `\Mor` (see `trees/macros.tree`).

---

## 3. Learning Diary & RSS

- **Entries**: Use `\mdblock{YYYY-MM-DD}{}`.
- **RSS Processing**: `just stars` generates JSON for integration.
- **Citations**: `\citef{ref-id}` (full title) or `\citek{ref-id}` (key-only).

---

## 4. Build & Validation

- **Tree Validation**: Ensure proper syntax with `just build`.
- **LaTeX**: Use `./lize.sh <tree-id>` for PDF generation.

---

## 5. Subject-Specific Guidelines

| Prefix | Topic                  |
|--------|------------------------|
| `uts`  | General math/notes     |
| `ag`   | Algebraic geometry     |
| `tt`   | Type theory            |
| `ca`   | Category theory        |

---

## 6. Common Pitfalls

1. Forgetting `\import{macros}`.
2. Incorrect tree file naming (`xxx-NNNN`).
3. Mixing math notation styles.

---

*For general coding rules and workflows, refer to [AGENTS.md](../AGENTS.md).*