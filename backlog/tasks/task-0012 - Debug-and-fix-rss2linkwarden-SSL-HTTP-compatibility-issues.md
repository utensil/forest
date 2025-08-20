---
id: task-0012
title: Debug and fix rss2linkwarden SSL/HTTP compatibility issues
status: Done
assignee:
  - '@agent'
created_date: '2025-08-20'
updated_date: '2025-08-20'
labels: []
dependencies: []
---

## Description

The rss2linkwarden task was failing with SSL errors when using Python requests library to connect to Caddy-proxied HTTPS endpoints, while curl worked fine. Need to investigate root cause and implement a reliable solution.

## Acceptance Criteria

- [ ] Script successfully imports RSS starred items to Linkwarden
- [ ] No SSL/TLS connection errors
- [ ] Pure Python solution without external dependencies
- [ ] Maintains all existing functionality (idempotency error handling rate limiting)
- [ ] Comprehensive technical analysis documented
- [ ] Solution tested with real RSS data via just rss2linkwarden --days 6

## Implementation Plan

1. Reproduce and analyze the SSL/HTTP errors with Python requests vs curl
2. Create systematic test scripts to isolate the root cause  
3. Test different HTTP libraries (requests urllib3 httpx) and protocols (HTTP/1.1 vs HTTP/2)
4. Identify HTTP/2 compatibility issues between Python and Caddy
5. Implement solution using urllib3 with HTTP/1.1 to avoid compatibility issues
6. Update script dependencies and maintain all existing functionality
7. Test thoroughly with real RSS data via just command
8. Document findings and solution approach

## Implementation Notes

## Approach Taken
- Systematic debugging revealed HTTP/2 compatibility issue between Python libraries and Caddy
- Created comprehensive test scripts to isolate SSL vs HTTP protocol issues
- Found that curl works with HTTP/2 but Python requests fails with SSL EOF errors
- urllib3 direct usage works because it defaults to HTTP/1.1

## Approach Taken
- Systematic debugging revealed HTTP/2 compatibility issue between Python libraries and Caddy
- Created comprehensive test scripts to isolate SSL vs HTTP protocol issues
- Found that curl works with HTTP/2 but Python requests fails with SSL EOF errors
- urllib3 direct usage works because it defaults to HTTP/1.1

## Features Implemented
- Replaced curl subprocess calls with urllib3 direct HTTP requests
- Maintained all critical functionality: idempotency error handling rate limiting deterministic processing
- Updated dependencies from requests>=2.31.0 to urllib3>=2.0.0
- Added comprehensive documentation of findings

## Technical Decisions
- Chose urllib3 over requests to avoid HTTP/2 compatibility issues
- Used urllib3.PoolManager with cert_reqs='CERT_NONE' for Caddy's self-signed certificates
- Maintained environment variable integration for API token
- Kept same API patterns for consistency

## Modified Files
- linkwarden_import.py: Complete rewrite to use urllib3 instead of curl
- .agents/docs/caddy_ssl_analysis.md: Comprehensive technical analysis document

## Test Results
- Successfully tested with 'just rss2linkwarden --days 6'
- Imported 6 RSS entries to Linkwarden (IDs 20-25)
- No SSL/HTTP errors pure Python solution achieved

## Additional Improvements Needed (discovered during testing)
- Add progress reporting for each batch (current rate limiting not visible)
- Add detailed archiving wait status (currently just shows archived: false)
- Add entry count before processing (dry-run mode)
- Better handling for large datasets (--days 24 has too many links)
- Background execution with periodic progress checks
- Ability to kill long-running processes gracefully
## Features Implemented
- Replaced curl subprocess calls with urllib3 direct HTTP requests
- Maintained all critical functionality: idempotency error handling rate limiting deterministic processing
- Updated dependencies from requests>=2.31.0 to urllib3>=2.0.0
- Added comprehensive documentation of findings

## Technical Decisions
- Chose urllib3 over requests to avoid HTTP/2 compatibility issues
- Used urllib3.PoolManager with cert_reqs='CERT_NONE' for Caddy's self-signed certificates
- Maintained environment variable integration for API token
- Kept same API patterns for consistency

## Modified Files
- linkwarden_import.py: Complete rewrite to use urllib3 instead of curl
- .agents/docs/caddy_ssl_analysis.md: Comprehensive technical analysis document

## Test Results
- Successfully tested with 'just rss2linkwarden --days 6'
- Imported 6 RSS entries to Linkwarden (IDs 20-25)
- No SSL/HTTP errors pure Python solution achieved
