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

### 1. File Header
Common imports and metadata at the start of the file:

```
\import{other-tree}  # Import definitions from another tree
\tag{topic}         # Topic tags for categorization
```

### 2. Content Elements

#### Basic Structure
Every tree must have properly nested structure elements:

```
\title{Title of the Note}  # Optional but recommended
\p{Paragraph text}        # Paragraphs must be explicitly marked
\subtree{                 # Create a subsection
  \title{Subsection}
  \p{Content...}
}
```

#### Lists and Items
```
\ol{  # Ordered list
  \li{First item} 
  \li{Second item}
}

\ul{  # Unordered list 
  \li{Item one}
  \li{Item two}
}
```

#### Text Styling and References
```
\strong{bold text}
\em{italic text}
\code{monospace}
\newvocab{new term}      # Highlight new terminology
\vocab{previously defined term}
\related{hidden reference text}

# Citations and References
\citek{reference-id}     # Citation with brackets
\citet{tag}{ref-id}     # Citation with specific tag
\citelink{url}          # URL citation
```

#### Math Content
```
#{inline math}           # Inline KaTeX math
##{display math}         # Display KaTeX math

\eqtag{eq1}{equation}    # Numbered equation
\eqnotag{equation}       # Unnumbered equation
```

#### Diagrams and Figures
```
\tikzfig{                # TikZ diagram
  \begin{tikzcd}
    # TikZ content
  \end{tikzcd}
}

\figure{
  content
  \figcaption{Caption text}
}
```

#### Special Blocks
```
\proof{                  # Proof block (not in TOC)
  \p{Proof content...}
}

\collapsed{title}{       # Collapsible section
  content
}

\quote{quoted text}      # Blockquote
```

### 3. References and Links

#### Internal Links
```
[link text](tree-id)     # Link to another tree
\vocabk{term}{tree-id}   # Link to term definition
```

#### External Links
```
\meta{external}{url}     # External resource metadata
\link{url}              # Simple URL link
```

### 4. Custom Components

#### Component Definition
```
\def\customblock[param1][param2]{
  content with #param1 and #param2
}
```

#### Taxonomy Markers
```
\taxon{definition}       # Mark as definition
\taxon{theorem}         # Mark as theorem
\taxon{lemma}          # Mark as lemma
```

## Common Patterns

### Math Note Structure
```
\refcardt{type}{name}{tag}{reference}{
  \p{Statement...}
  
  \proof{
    \p{Proof details...}
  }
}
```

### Translation Block
```
\translation/tp[english]{[foreign]{
  Parallel text content
}}
```

### Code Block
```
\codeblock[language]{
  code content
}
```

## Best Practices
- Import shared macros at the start
- Use proper taxonomy markers
- Structure content hierarchically 
- Cite sources with proper references
- Use newvocab for first occurrence of terms
- Link to term definitions with vocabk
- Include proofs in collapsible blocks
- Tag notes for topic organization

## Common Pitfalls
- Missing \p{} around paragraphs
- Incorrect nesting of blocks
- Uncited theorems/definitions
- Missing taxonomy markers
- Improper citation format
- Unlinked terminology
