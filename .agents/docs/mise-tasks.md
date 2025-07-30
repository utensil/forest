# Writing Idiomatic Mise Tasks

This guide summarizes best practices for writing mise tasks in this repository, based on current conventions and lessons learned from common mistakes.

## Key Principles

-   **Location & Naming:**

    -   Place task scripts in `mise-tasks/<category>/` (e.g., `mise-tasks/build/`).
    -   Do **not** use file extensions (e.g., use `build_and_reload`, not `build_and_reload.sh`).
    -   Make scripts executable (`chmod +x`).

-   **Task Invocation:**

    -   Invoke tasks using `mise run <category>:<taskname>` (e.g., `mise run build:build_and_reload`).
    -   Do **not** invoke scripts directly (e.g., avoid `./mise-tasks/build_and_reload.sh`).
    -   Do **not** use path-based invocation (e.g., avoid `mise run build/build_and_reload`).

-   **Script Headers:**

    -   Include a shebang (e.g., `#!/bin/bash`).
    -   Add `#MISE` metadata headers as needed for sources, outputs, and dependencies.

-   **Orchestration:**

    -   For multi-step tasks, orchestrate subtasks using `mise run <category>:<subtask>` within the script.
    -   Use background jobs and `wait` judiciously for concurrency, but ensure correct sequencing for dependent steps.

-   **Documentation:**
    -   Add concise comments explaining the task’s purpose and any non-obvious logic.
    -   Use `AGENT-NOTE:` comments for AI/human maintainers.

## Common Pitfalls

-   **Wrong:** Placing orchestration logic in a shell script outside the `mise-tasks/` hierarchy or with a `.sh` extension, then invoking it directly.
-   **Wrong:** Using path-based invocation (`mise run build/build_and_reload`) instead of colon-based (`mise run build:build_and_reload`).
-   **Right:** Place the script in `mise-tasks/build/`, make it executable, and invoke with `mise run build:build_and_reload`.

## Example

```bash
#!/bin/bash
# Orchestrate build and reload
set -e
mise run build:xml_to_html &
pid1=$!
wait $pid1
# ...
```

---

This guide will help you write idiomatic, maintainable mise tasks that integrate smoothly with the project’s workflow.
