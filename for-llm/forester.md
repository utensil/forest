# Forester Documentation for AI Assistants

## Overview and Configuration

### Basic Overview
Forester is a tool for creating and managing collections of interconnected notes ("trees") organized into "forests". It uses a markup language similar to LaTeX with influences from Markdown.

A tree file can:
- Export macros for use by other trees using \export{macros}
- Import macros from other trees using \import{name}
- Define new macros with \def\name[param]{definition}
- Use topic tags either as comments (% tag1 tag2) or commands (\tag{tag})

## File Structure
- Trees are stored as `.tree` files
- Each tree has a unique address in format `xxx-NNNN` where:
  - `xxx` is a namespace prefix (often user initials)
  - `NNNN` is a base-36 number
- References are stored in `refs/` subdirectory
- Configuration via `forest.toml`

## Tree Structure

### 1. File Header
Common imports and metadata at the start of the file:

```
\import{macros}     # Import common macros
\import{other-tree} # Import definitions from another tree
% topic1 topic2     # Topic tags as comments
\tag{topic1}        # Topic tags via command
\tag{topic2}
\taxon{type}       # Document type classification
```

### 2. Important Concepts

#### Document Types
Common document types marked with \taxon:
- person: Author/person profile
- reference: Citation reference
- definition/theorem/lemma: Mathematical content 
- root: Top-level index document
- eq: Equation reference

#### Tags
Common tag categories:
- Subject areas: clifford, hopf, spin, tt (category theory), ag (algebraic geometry)
- Status: draft, notes, exp (experimental)
- Type: tech, macro (macro definitions)

#### References
Reference cards marked with \refcardt format:
```
\refcardt{type}{name}{section}{citation}{
  \p{Statement...}
  
  \proof{
    \p{Proof details...}
  }
  
  \tikzfig{     # Optional diagrams
    \begin{tikzcd}
      # Diagram content
    \end{tikzcd}
  }
  
  \ol{          # Optional lists
    \li{Point 1}
    \li{Point 2}
  }
}
```

Types include:
- definition, theorem, lemma
- construction, observation, convention 
- corollary, axiom, example, exercise
- proof, discussion, remark, notation

Common patterns:
- Mathematical definitions with proofs
- Category theory with string diagrams
- Physics/geometry with TikZ figures
- Algorithms with pseudocode

### 2. Mathematical Typesetting

#### Category Theory Macros
Common category theory notation:
```
# Categories
\Cat        # Category of categories 
\Set        # Category of sets
\Grp        # Category of groups
\Top        # Category of topological spaces
\Poset      # Category of posets
\Preord     # Category of preorders
\Topoi      # Category of topoi

# Basic operators
\dom        # Domain operator
\cod        # Codomain operator
\Ob         # Objects functor
\Arr        # Arrows functor
\Mor        # Morphisms
\Sub        # Subobjects

# Common symbols
\fatsemi    # Composition operator ⨟
\cp         # Bullet composition •
\monic      # Monomorphism ↣
\epic       # Epimorphism ↠
\equiv      # Equivalence ~
\iso        # Isomorphism ≅
```

#### String Diagrams
Components for building string diagrams:

```
# Base components
\category/new              # New category box
\functor/new              # New functor wire
\nat-transf/new           # Natural transformation dot

# Compositions
\functor/comp/new         # Compose functors horizontally  
\nat-transf/vcomp/new     # Vertical composition of transformations
\nat-transf/hcomp/new     # Horizontal composition
\nat-transf/pasting/new   # Pasting diagram

# Constructors
\create/fun[name][dom][cod]     # Named functor
\create/nat[name][dom][cod]     # Named transformation
\create/wire[total][nth][d][c]  # Wire in diagram
\create/dot[w][t][n][nat][s][p] # Dot on wire

# Special constructions
\joinfun/new              # Join functors
\homfun/new              # Hom functor
\cupfun/new              # Cup/cap diagrams
\naturality/new          # Naturality squares
\adjunction/new          # Adjunction diagrams
```

#### String Diagram Styling
Control diagram appearance:
```
[fill]{fill=none}        # Background fill
[opacity]{0.6}           # Element opacity
[symbol]{dot|circ}       # Node style
[height]{4}              # Diagram height
[width]{2}               # Diagram width
```

### 3. Content Elements

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

Common math operator patterns:
```
\def\op{\operatorname{op}}     # Named operators
\def\symbol{\mathcal{S}}       # Mathcal symbols
\def\decorated[x]{\x^{*}}      # Parameterized operators
\def\spacing{\kern-2pt}        # Fine spacing control
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

### 4. Custom Components and TikZ Integration

#### Object Definitions
Objects are defined using nested property blocks:
```
\def\object/name{
  \object[self]{
    [property1]{value1}
    [property2]{value2}
    [nested/prop]{value3}
    [draw]{
      \draw commands...
    }
  }
}
```

Properties can be accessed with \self#property syntax:
```
\coordinate (\self#id) at (\self#origin);
\draw (\self#start) -- (\self#end);
```

#### TikZ Integration
Common TikZ patterns:
```
# Basic drawing
\draw (x,y) -- (x2,y2);
\filldraw[style] (x,y) circle (r);
\shade[options] ... ;

# Coordinate systems
\coordinate (name) at (x,y);
\node[style] at (x,y) {text};

# Transformations
\begin{scope}[transform]
  drawing commands...
\end{scope}

# Pictures
name/.pic={
  drawing commands...
}
```

#### Style Definitions
```
\tikzset{
  style/.cd,
  property/.store in=\variable,
  property=default,
}

\colorlet{name}{color!percent!color}
\tikzstyle{name}=[options]
```

#### Component Definition
```
# Basic macro
\def\name[param1][param2]{
  content with #param1 and #param2
}

# With verification
\def\name{
  \verify{param1}{type}
  content...
}

# Complex object
\def\name/new{
  \object[self]{
    [props]{...}
    [draw]{...}
  }
}
```

#### Special Commands
```
\verb~special chars~     # Verbatim text
\ensuremath{math}        # Ensure math mode
\lVert x \rVert         # Math delimiters
```

#### Taxonomy Markers
```
\taxon{definition}       # Mark as definition
\taxon{theorem}         # Mark as theorem
\taxon{lemma}           # Mark as lemma
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

## Organization Patterns

### Note Types
- Root notes (\tag{root}): Entry points and indexes
- Draft notes (\tag{draft}): Work in progress
- Macro notes (\tag{macro}): Shared definitions
- Experimental notes (\tag{exp}): Trials and tests
- Special notes: person, reference, equation

### Query Patterns
Common queries for organizing notes:
```
# Find notes without a home
\def\query/normal{
  \compl{
    \union{\tag{root}}{\tag{draft}}{\tag{macro}}
    {\tag{exp}}{\taxon{person}}{\taxon{reference}}
  }
}

# Find lost notes not transcluded anywhere
\def\query/root/transcluded{
  \union-fam-rel{\tag{root}}{\paths}{\outgoing}{\transclusion}
}
\def\query/lost{
  \isect{\query/normal}{\compl{\query/root/transcluded}}
}
```

### Documentation Patterns
- Learning diaries with dated entries
- Topic-based note collections
- Cross-referenced theorem networks
- Citation and bibliography systems

## Best Practices
- Import shared macros at the start
- Use proper taxonomy markers
- Structure content hierarchically 
- Cite sources with proper references
- Use newvocab for first occurrence of terms
- Link to term definitions with vocabk
- Include proofs in collapsible blocks
- Tag notes for topic organization
- Query to find orphaned/lost notes
- Date entries in learning diaries

## Common Pitfalls
- Missing \p{} around paragraphs
- Incorrect nesting of blocks
- Uncited theorems/definitions
- Missing taxonomy markers
- Improper citation format
- Unlinked terminology
