---
id: task-0014
title: Implement proactive link deduplication and intelligent updates
status: Done
assignee: []
created_date: '2025-08-20'
updated_date: '2025-08-20'
labels: []
dependencies: []
---

## Description

Instead of creating duplicate links and getting rejected, proactively search for existing links by externalURL and intelligently update them. When the same article appears on different aggregators (HN, Lobsters), add aggregator links to description as markdown links while preserving existing content.

## Acceptance Criteria

- [ ] Search existing links by externalURL before creating new ones
- [ ] Update existing links with new aggregator URLs in description
- [ ] Preserve existing description content when updating
- [ ] Avoid adding duplicate aggregator links
- [ ] Use markdown format for aggregator links similar to stars.py
- [ ] Handle cases where only aggregator URL differs from original
- [ ] Maintain idempotent behavior - multiple runs produce same result
- [ ] Clear logging of update vs create decisions

## Implementation Notes

## Approach Taken
- Analyzed Linkwarden OpenAPI specification to understand correct update API format
- Implemented proactive link search by externalURL before creating new entries
- Built intelligent aggregator detection for Lobsters, Hacker News, Reddit
- Created update system that preserves existing content while adding new aggregator links
- Used proper API payload format with all required fields (collection, ownerId, tags)

## Features Implemented  
- search_existing_link() function to find links by externalURL
- extract_aggregator_info() to detect aggregator sources and URLs
- update_link_description() with proper OpenAPI format compliance
- create_or_update_link() with intelligent decision making
- Enhanced stats tracking: created, updated, exists, failed, archived, duplicates
- Markdown aggregator links: **Discussion:** [Lobsters](https://lobste.rs/s/xyz)

## Technical Decisions
- Used Linkwarden OpenAPI spec to ensure correct API payload format
- Required fields: id, name, url, description, collection{id,ownerId}, tags[]
- Proactive search prevents duplicate creation attempts
- Preserves existing description content when adding aggregator info
- Avoids adding duplicate aggregator links to same entry

## Modified Files
- linkwarden_import.py: Complete proactive deduplication and update system

## Test Results
- MAJOR SUCCESS: 'updated': 3, 'exists': 3, 'created': 0, 'failed': 0
- Successfully added Lobsters aggregator links to 3 existing entries
- Perfect deduplication - no duplicate entries created
- Verified aggregator links appear correctly in descriptions
- Idempotent behavior - multiple runs produce consistent results

## Example Output
Updated link description: '**Discussion:** [Lobsters](https://lobste.rs/s/nu7cjz)'
This provides users with direct links to discussions on aggregator sites.
