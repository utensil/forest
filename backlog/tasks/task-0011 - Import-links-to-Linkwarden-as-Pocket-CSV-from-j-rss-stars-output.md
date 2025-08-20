- Import starred RSS links to Linkwarden/Wallabag JSON from `just rss-stars` output

Implementation now uses wallabag_import.py, which reads JSON lines from `just rss-stars "linkwarden"` and outputs Linkwarden-compatible Wallabag import JSON. The script:
- Maps all possible fields from the NetNewsWire SQLite export to the Wallabag/Linkwarden import schema, with robust defaults and schema compliance.
- Accepts a `--days N` parameter (default 7, -1 for all) to filter by datePublished or dateArrived, matching the logic in stars.py.
- Is idempotent, deterministic, robust, and documented per AGENTS.md.
- Usage: `just rss2linkwarden --days 30 > import.json` (see justfile for details).

Acceptance Criteria:
- [x] The script reads `just rss-stars "linkwarden"` output and writes valid Linkwarden/Wallabag import JSON.
- [x] All possible equivalent fields are mapped; others are left empty or with a valid status.
- [x] The script is idempotent and robust, following AGENTS.md guidelines.
- [x] Documentation and usage instructions are included.
- [x] All code and documentation changes are committed with [AGENT] tag.

Execution Notes:
- Pocket CSV is not used; Linkwarden/Wallabag JSON import is now the supported workflow.
- Field mapping, script design, and parameter filtering were discussed and implemented to match project conventions.
- See wallabag_import.py and justfile for details.
- Verified with jq and sample data for correct filtering and output.
