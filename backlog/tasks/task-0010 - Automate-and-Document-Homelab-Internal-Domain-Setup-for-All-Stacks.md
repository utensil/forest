- Automate and Document Homelab Internal Domain Setup for All Stacks

Implement a robust, idempotent workflow to manage /etc/hosts entries for all stacks, ensuring every [stack].homelab.internal domain is routed to a configurable IP (default: 127.0.0.1).
- Create scripts/prep_homelab.py to scan stacks/ subdirectories and write a clearly marked block to /etc/hosts.
- Script must use sudo if needed, be safe for reentry, and support a custom IP argument.
- Add a just prep-homelab [IP] task to invoke the script.
- Update the Caddy stack README to instruct users to use this automation, replacing manual /etc/hosts edits.
- Implement and document the Caddy stack in stacks/caddy/ with:
    - Dockerfile that copies the Caddyfile into the image
    - compose.yml using build context, not bind mounts
    - Example Caddyfile for reverse proxying stack subdomains
    - README with clear, user-agnostic instructions and integration with the hosts automation
- Solution must be robust, reentrant, and fully documented.

Acceptance Criteria:
- [ ] Running just prep-homelab adds/updates a block in /etc/hosts for all current stacks, with no duplication or corruption.
- [ ] The Caddy stack README clearly documents this workflow.
- [ ] The solution is robust, reentrant, and works with any set of stack subdirectories.
- [ ] All code and documentation changes are committed with [AGENT] tag.

Execution Notes:
- The script uses marker comments for safe block replacement.
- The just task defaults to 127.0.0.1 but allows a custom IP.
- The README now points users to the just task for all internal domain setup.

