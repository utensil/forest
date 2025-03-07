# Forester Documentation for AI Assistants

## Overview
Forester is a tool for creating and managing collections of interconnected notes ("trees") organized into "forests". It uses a markup language similar to LaTeX with influences from Markdown.

## File Structure
- Trees are stored as `.tree` files
- Each tree has a unique address in format `xxx-NNNN` where:
  - `xxx` is a namespace prefix (often user initials)
  - `NNNN` is a base-36 number
- Configuration via `forest.toml`

## Tree Structure
Each tree file has two main sections:

### 1. Frontmatter
Metadata declarations at the start of the file:

```
\title{My Tree Title}
\author{username}
\date{YYYY-MM-DD}
\taxon{type}  # Optional classification like: definition, theorem, etc.
\parent{xxx-NNNN}  # Optional parent tree reference
```

### 2. Mainmatter 
The main content using Forester markup:

Basic Elements:
```
\p{paragraph text}  # Paragraphs must be explicitly marked
\em{italic text}
\strong{bold text}
\code{monospace text}

\ol{  # Ordered list
  \li{first item}
  \li{second item}
}

\ul{  # Unordered list
  \li{bullet item}
  \li{another item}
}
```

Math Content:
```
#{inline math}  # Inline math using KaTeX
##{display math}  # Display math using KaTeX

\tex{preamble}{body}  # LaTeX content rendered to SVG
```

Links and Transclusion:
```
[link text](xxx-NNNN)  # Link to another tree
[[xxx-NNNN]]  # Wiki-style link showing tree's title

\transclude{xxx-NNNN}  # Include another tree as a subsection
```

## Special Features

### Transclusion Options
Control how trees are transcluded using fluid bindings:

```
\scope{
  \put\transclude/title{Override Title}
  \put\transclude/expanded{false}  # Collapsed by default
  \put\transclude/heading{false}   # Inline contents
  \put\transclude/metadata{true}   # Show metadata
  \put\transclude/numbered{false}  # Hide numbering
  \transclude{xxx-NNNN}
}
```

### Queries
Generate sections by querying the forest:

```
\query{
  \query/and{
    \query/author{username}
    \query/taxon{definition}
    \query/tag{important}
  }
}
```

### Namespaces
Organize identifiers hierarchically:

```
\namespace\foo{
  \def\bar{...}  # Accessible as \foo/bar
}

\open\foo  # Import foo's definitions directly
```

## XML Output
Forester generates XML that is transformed to HTML via XSLT. Custom XML can be emitted using:

```
\xmlns:ns{uri}  # Declare namespace
\<ns:elem>[attr]{value}{content}  # Generate XML element
```

## Common Conventions
- Tree titles should be lowercase (except proper nouns)
- Each paragraph needs explicit \p{...}
- Keep trees atomic and focused
- Use transclusion rather than copy-paste
- Prefer descriptive titles
- Include creation dates
