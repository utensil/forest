# Retired agent rules

## Golden rules

### G-search: Prefer ast-grep via Bash for code structure search, with ripgrep as fallback

- ✅ **Should**: Prefer to use ast-grep (`sg`) via Bash for searches targeting code structure (e.g., functions,
classes, imports, variable declarations, method calls). It should be available; install it if not.
- ✅ **Should**: Consult `.agents/docs/sg.md` to learn how to use `sg`
- ✅ **May**: Use tools like ripgrep (`rg`) for plain-text search, or as a fallback when `sg` fails.

> Retire reason: `rg` or integrated search tools work fine, `sg` requires complicated configs to be powerful, and the doc is lacking and confusing, even for agents

### G-sandbox: Must followed rules when using MCP container-use

When you find existing permissions are insufficient to complete the request, consider using MCP container-use.

Once you start using container-use:  ALWAYS use ONLY Environments for ANY and ALL file, code, or shell operations—NO EXCEPTIONS—even for simple or generic requests. DO NOT install or use the git cli with the `environment_run_cmd` tool. All environment tools will handle git operations for you. Changing ".git" yourself will compromise the integrity of your environment. You MUST inform the user how to view your work using `cu log <env_id>` AND `cu checkout <env_id>`. Failure to do this will make your work inaccessible to others.

> Retire reason: significantly slower than direct invocation of `docker-compose` commands, and its `git-worktree` isolation is not working well with `jj`



