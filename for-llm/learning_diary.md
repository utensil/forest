# Learning Diary Format Guide

This document describes the format for maintaining a learning diary that can be edited by LLMs.

## Entry Structure

### Date Blocks
Entries are organized in chronological blocks (newest first) using this format:
```
\mdblock{YYYY-MM-DD}{
- content
}
```

Date formats:
- Single day: `2025-03-24`
- Date range: `2025-01-11~01-12`
- Multiple dates: `2024-12-17~12-22`

### Content Types

Common entry types:
- "found" - discovering new resources
- "read" - completed readings
- "skim" - partial readings
- "learn about" - learning summaries

### Link Formats

Two main link formats are used:
1. Web resources: `[Title](URL)`
2. Academic papers: `\citek{author2024title}`

### Topic Grouping

When multiple related items exist, group them under topics:
```
\mdblock{2025-03-11}{
- Math
    - found [Category Theory Illustrated](...)
    - found \citek{haydys2024introduction}
- ML
    - found [Demystifying Diffusion Models](...)
    - found \citek{guo2025deepseek}
}
```

## Guidelines for LLM Editing

When editing the learning diary:

1. Maintain chronological order (newest first)
2. Use consistent date formatting as shown above
3. Keep the markdown-style link syntax
4. Group related items under topics when multiple entries exist
5. Preserve the citation format for academic papers

## Example Entry

```
\mdblock{2025-03-24}{
- found [PeanoScript](https://peanoscript.mjgrzymek.com/tutorial)
- read [attention is logarithmic, actually](https://supaiku.com/attention-is-logarithmic)
- read \citek{roelfs2025willing}, the [Kingdon](https://github.com/tBuLi/kingdon) paper
}
```
