# Learning Diary Format Guide

This document describes the format for maintaining a learning diary that can be edited by LLMs.

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

## Processing RSS Stars

When processing output from `just rss-stars`, follow these guidelines:

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
