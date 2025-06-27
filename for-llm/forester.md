# Forester Documentation for AI Assistants

## Overview and Configuration

### Basic Overview
Forester is a tool for creating and managing collections of interconnected notes ("trees") organized into "forests". It uses a markup language similar to LaTeX with influences from Markdown.

A tree file can:
- Export macros for use by other trees using \export{macros}
- Import macros from other trees using \import{name}
- Define new macros with \def\name[param]{definition}
- Use topic tags either as or commands (\tag{tag})

## File Structure
- Trees are stored as `.tree` files
- Each tree has a unique address in format `xxx-NNNN` where:
  - `xxx` is a namespace prefix (often subject area)
  - `NNNN` is a base-36 number (allowing digits 0-9 and letters A-Z)
- References are stored in `refs/` subdirectory
- Configuration via `forest.toml`

## Tree Structure

### 1. File Header
Common imports and metadata at the start of the file:

```
\import{macros}     # Import common macros
\import{other-tree} # Import definitions from another tree
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
Reference cards marked with \refcardt format (formal mathematical statements):
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

Examples from actual tree files:
```forester
\refcardt{lemma}{Yoneda}{4.2.1}{leinster2016basic}{
\p{
Let #{\C} be a \vocabk{locally small}{tt-000A} category. Then
##{
\Nat(\fH_X, \fF) \cong \fF(X)
}
\vocabk{naturally in}{tt-001H} #{X \in \C} and #{\fF \in\left[\C^{\mathrm{op}}, \Set \right]}.
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

#### Forest-Specific Patterns

**Tree Organization**:
```forester
\import{macros}
\tag{root}                # Top-level index trees
\tag{draft}              # Work in progress
\tag{interest}           # Interest tracking
\put\transclude/numbered{false}

\note{title}{
  \block{section}{
    content...
  }
}
```

**Learning Diary Format**:
See `for-llm/learning_diary.md` for comprehensive documentation on learning diary patterns and RSS integration.

**Transclusion and Queries**:
```forester
\transclude{tree-id}     # Include another tree
\scope{
  \put\transclude/expanded{false}
  \query{
    \open\query
    \isect{\tag{draft}}{\compl{\tag{completed}}}
  }
}
```

**Special Content Types**:
```forester
\card{type}{title}{content}    # Content card
\note{title}{content}          # Structured note
\block{title}{content}         # Content block
\mdnote{title}{markdown-style content}
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
\citef{reference-id}     # Citation showing full paper title (learning diary)
\citek{reference-id}     # Citation for whole papers/books (mathematical content)
\citet{section}{ref-id}  # Citation with specific section/theorem (mathematical content)
\citelink{url}          # URL citation

# Citation Examples:
# Learning diary: read \citef{ren2025deepseekproverv2}
# Mathematical: follows \citek{leinster2016basic}
# Specific: naturally in X \citet{1.3.12}{leinster2016basic}
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

### Forest-Specific Note Types
Based on actual tree file patterns:

**Subject-based prefixes**:
- `uts-NNNN`: General mathematical notes and learning diary
- `ag-NNNN`: Algebraic geometry concepts and constructions
- `tt-NNNN`: Type theory and categorical logic
- `ca-NNNN`: Category theory fundamentals
- `spin-NNNN`: Clifford algebras and spin groups
- `hopf-NNNN`: Hopf algebras and quantum groups

**Tag-based organization**:
- Root notes (`\tag{root}`): Entry points and indexes
- Draft notes (`\tag{draft}`): Work in progress
- Macro notes (`\tag{macro}`): Shared definitions
- Experimental notes (`\tag{exp}`): Trials and tests
- Interest tracking (`\tag{interest}`): Learning and research interests
- Special taxons: `person`, `reference`, `equation`

### Actual Query Patterns
From Forest tree files:
```forester
# Find draft notes by topic
\query{
    \open\query
    \isect{\tag{draft}}{\compl{\union{\tag{tt}}{\tag{ag}}{\tag{clifford}}{\tag{tech}}}}
}

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
- **Learning diaries**: See `for-llm/learning_diary.md` for comprehensive format documentation
- **Mathematical notes**: LaTeX PDF generation with `\meta{pdf}{true}`
- **Topic collections**: Organized by mathematical subjects
- **Cross-referenced networks**: Using `\vocabk{term}{tree-id}` for definitions
- **Citation systems**: `\citef{}` (learning diary), `\citek{}` and `\citet{}` (mathematical content)
- **Macro libraries**: Reusable mathematical notation and string diagrams

## Best Practices
Based on actual Forest usage patterns:

### Content Organization
- Import shared macros at the start: `\import{macros}` or `\import{spin-macros}`
- Use proper taxonomy markers: `\taxon{definition}`, `\tag{subject-area}`
- Structure content hierarchically with `\note{}`, `\block{}`, `\subtree{}`
- Add metadata for PDF generation: `\meta{pdf}{true}`, `\author{}`, `\date{}`

### Mathematical Content
- Use `\refcardt{}` for formal mathematical statements
- Include proofs in `\proof{}` blocks within reference cards
- Use `\vocabk{term}{tree-id}` to link to definitions
- Use `\newvocab{}` for first occurrence of terms
- Employ mathematical macros from subject-specific macro files

### Learning Diary Management
See `for-llm/learning_diary.md` for detailed documentation on learning diary format, RSS processing, and best practices.

### Cross-References and Citations
- Cite sources with proper references: `\citek{}` for whole papers, `\citet{}` for specific sections
- Use internal tree linking: `[text](tree-id)` or `[[tree-id]]`
- Create queries to find orphaned/lost notes
- Tag notes for proper topic organization

## Common Pitfalls
Based on Forest development experience:

### Syntax Issues
- Missing `\p{}` around paragraphs (Forester requirement)
- Incorrect nesting of blocks and commands
- Not following tree file naming conventions (`xxx-NNNN` format)
- Forgetting to import required macro files

### Content Issues
- Uncited theorems/definitions in mathematical content
- Missing taxonomy markers (`\taxon{}`, `\tag{}`)
- Improper citation format or missing references
- Unlinked terminology that should use `\vocabk{}`

### Organization Issues
- Not updating learning diary consistently (see `for-llm/learning_diary.md` for guidelines)
- Missing transclusion in root/index trees
- Not using appropriate subject prefixes for new trees
- Creating orphaned notes without proper linking
