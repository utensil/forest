# Learning Diary Format Guide

This document describes the format for maintaining a learning diary that can be edited by LLMs, based on the actual patterns used in `trees/uts-0018.tree`.

## Entry Structure

### Date Blocks
Entries are organized by arrival date (newest first) using this format:
```
\mdblock{YYYY-MM-DD}{
- content
}
```

The block date should be the publication date (datePublished) converted from Unix timestamp.
Entries are sorted by arrival date (dateArrived) in descending order within the diary.

Date formats:
- Single day: `2025-06-10`
- Date range: `2025-01-11~01-12` 
- Multiple dates: `2024-12-17~12-22`
- Subtree grouping: `\subtree[2025-06]{ \title{June, 2025} ... }`

### Content Types

Common entry types based on actual usage:
- **"read"** - completed readings: `read [Lightweight Diagramming for Lightweight Formal Methods](...)`
- **"found"** - discovering new resources: `found [backrest](https://github.com/garethgeorge/backrest)`
- **"skim"** - partial readings: `skim [modern-latex: A short guide to LaTeX](...)`
- **"learn about"** - learning summaries: `learn about [Glean](https://glean.software/)`
- **"try"** - testing/experimenting: `try [genspark](https://www.genspark.ai/agents?id=...)`
- **"watch"** - video content: `watch [Chris Biscardi - Bevy: A case study](...)`
- **"investigate"** - research topics: `investigating DSPy (Demonstrate-Search-Predict)`
- **"work on"** - project activities: `work on native-land`

### Link Formats

Multiple link formats are used:
1. **Web resources**: `[Title](URL)`
2. **Academic papers**: `\citef{author2024title}` (shows full paper title in learning diary)
3. **Internal references**: `[[tree-id]]` for referencing other trees
4. **Escaped URLs**: `\verb>>>|URL>>>` for URLs with special characters
5. **Code repositories**: `[name](https://github.com/user/repo)`

**Note**: In mathematical content (non-diary trees), use `\citek{ref-id}` for whole papers and `\citet{section}{ref-id}` for specific sections/theorems instead of `\citef{}`.

### Topic Grouping

When multiple related items exist, group them under topics with proper nesting:
```
\mdblock{2025-06-10}{
- performance related
    - [Why doesn't Rust care more about compiler performance?](...)
    - [One Law to Rule All Code Optimizations](...)
    - [Simulating Time With Square-Root Space](...)
- OS related
    - [Munal OS: A graphical experimental OS with WASM sandboxing](...)
    - [The high-level OS challenge](...)
}
```

### Advanced Patterns

**Multi-level nesting** for detailed exploration:
```
\mdblock{2025-06-09}{
- read [Ditching HAProxy (in my homelab)](...)
    - found [Ran out of infrastructure titles](...) from the author
        - [backrest](https://github.com/garethgeorge/backrest)
            - for using `restic` to manage backup repos and plans
            - tested that `restore` and `mount` work
            - supports monitoring via [Healthchecks](https://healthchecks.io/)
}
```

**Paper citation chains**:
```
- read \citef{ren2025deepseekproverv2}
    - \citef{tie2025survey}
        - notes on LM could be based on this survey
    - \citef{zhang2025days}
        - \citef{guo2025deepseek}
            - should revisit
```

**Project work tracking**:
```
- work on native-land
    - trying to make GA and math benchmark work
    - pass CI on runpod
- work on formal-land, make Verso work
```

**Learning progressions**:
```
- learn 2 new formulas for Rubik's cube, see [[uts-016I]] and [[uts-016H]]
- learning speed solving Rubik's cube, see [[uts-016J]]
```

## Guidelines for LLM Editing

When editing the learning diary:

1. **Maintain chronological order** (newest first)
2. **Use consistent date formatting** as shown above
3. **Keep the markdown-style link syntax** with proper escaping when needed
4. **Group related items under topics** when multiple entries exist
5. **Preserve citation format** for academic papers using `\citef{}` (learning diary only)
6. **Use appropriate entry types** ("read", "found", "skim", "learn about", etc.)
7. **Maintain proper nesting** with 4-space indentation for sub-items
8. **Reference internal trees** using `[[tree-id]]` format
9. **Track project work** with "work on" entries
10. **Link related entries** across different dates when relevant

## Real Examples from the Learning Diary

**Simple daily entries**:
```
\mdblock{2025-06-10}{
- read [Lightweight Diagramming for Lightweight Formal Methods](https://blog.brownplt.org/2025/06/09/copeanddrag.html)
- found [Munal OS: A graphical experimental OS with WASM sandboxing](https://github.com/Askannz/munal-os)
- read comments on [Qwen3 embedding models](https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF)
}
```

**Complex nested exploration**:
```
\mdblock{2025-06-08}{
- read [Field Notes From Shipping Real Code With Claude](https://diwank.space/field-notes-from-shipping-real-code-with-claude)
    - great practice for `CLAUDE.md`, [AGENTS.md](https://github.com/julep-ai/julep/blob/main/AGENTS.md)
    - TODO: I should actually start working on my [CONVENTIONS.md](https://aider.chat/docs/usage/conventions.html)
    - related:
        - [I Read All Of Cloudflare's Claude-Generated Commits](https://www.maxemitchell.com/writings/i-read-all-of-cloudflares-claude-generated-commits/)
        - [MCP vs API](https://glama.ai/blog/2025-06-06-mcp-vs-api)
}
```

**Academic paper trails**:
```
\mdblock{2025-05-02}{
- read \citef{ren2025deepseekproverv2}
    - \citef{tie2025survey}
        - notes on LM could be based on this survey and the following papers related to r1
    - \citef{zhang2025days}
        - \citef{guo2025deepseek}
            - should revisit
    - found critics of r1/GRPO
        - \citef{liu2025understanding}
        - \citef{yue2025does}
}
```

**Project work documentation**:
```
\mdblock{2024-10-11~10-14}{
- work on [native-land](https://github.com/utensil/native-land) about GPU computation, see relavant README updates.
}
```

**Learning progressions with cross-references**:
```
\mdblock{2025-06-01}{
- learn 2 new formulas for Rubik's cube, see [[uts-016I]] and [[uts-016H]]
- learning speed solving Rubik's cube, see [[uts-016J]]
}
```

## Forester Integration

### Learning Diary as Part of Forest Structure
The learning diary in Forest is integrated as a special tree file (`trees/uts-0018.tree`) with specific structural requirements:

```forester
\import{macros}
\tag{root}
\put\transclude/numbered{false}
\loadjs{activity.js}

\note{learning diary}{
\p{I wish to keep a learning diary, to keep track of partial reading progress, and things learned during making things.}
}

\<html:div>[id]{learning-activity}{}

\subtree[2025]{
\title{Year 2025}
  \subtree[2025-06]{
  \title{June, 2025}
    \mdblock{2025-06-10}{
    - content entries...
    }
  }
}
```

### Best Practices for Forest Learning Diary Management
Based on actual Forest usage patterns:

- **Hierarchical organization**: Use year and month subtrees for better navigation
- **Activity tracking**: Load `activity.js` for interactive elements
- **Root tagging**: Mark as `\tag{root}` for inclusion in main navigation
- **Disable numbering**: Use `\put\transclude/numbered{false}` for cleaner display
- **Process RSS feeds**: Use `just stars` for automated entry generation from starred items
- **Consistent formatting**: Maintain `\mdblock{YYYY-MM-DD}{}` format throughout
- **Topic grouping**: Group related items under subject headers (e.g., "Math", "ML", "Tech")
- **Cross-referencing**: Link to other trees using `[[tree-id]]` format

### Learning Diary Pitfalls to Avoid
- **Inconsistent updates**: Not maintaining regular diary entries
- **Missing structure**: Not following proper `\mdblock{}` format
- **Poor organization**: Not grouping related items under topics
- **Broken links**: Using incorrect citation or reference formats
- **Date confusion**: Mixing datePublished vs dateArrived timestamps

## Processing RSS Stars

The `just stars` command processes starred RSS items from NetNewsWire and integrates them into the learning diary. It internally uses `just rss-stars` to extract JSON data from the RSS database, then processes it through `./stars.py`.

When processing output from `just stars`, follow these guidelines:

1. Data Structure Understanding:
   ```json
   {
     "title": "Article Title",
     "url": "Primary URL (often Lobste.rs)",
     "externalURL": "Original source URL", 
     "datePublished": Unix timestamp,
     "dateArrived": Unix timestamp
   }
   ```

2. URL Selection:
   - Always prefer externalURL when available
   - Only use url when externalURL is null
   - Links should be in format: `[Title](URL)`

3. Date Processing:
   - Convert Unix timestamp (datePublished) to YYYY-MM-DD format for the mdblock date
   - Validate the converted date:
     - Issue warnings for dates before 2020 or after 2026
     - Include the full entry details in the warning
     - Skip adding entries with invalid dates to the diary
   - Find or create the corresponding date block in the diary
   - If multiple entries share same date, group under same mdblock
   - Sort entries by dateArrived timestamp (newest first) within the diary

4. Entry Integration:
   - Add entries under existing date blocks if present
   - Create new date blocks if needed
   - Use the "read" prefix for completed readings
   - Group related items under topic headers if multiple exist

Example transformation:
```json
{
  "title": "Example Article",
  "url": "https://lobste.rs/s/example",
  "externalURL": "https://original.com/article",
  "datePublished": 1742748008
}
```
Becomes:
```
\mdblock{2025-03-24}{
- read [Example Article](https://original.com/article)
}
```

Always maintain the diary's existing structure and formatting conventions while integrating new entries.
