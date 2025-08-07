### G-sandbox: Must followed rules when using MCP container-use

When you find existing permissions are insufficient to complete the request, consider using MCP container-use.

Once you start using container-use:  ALWAYS use ONLY Environments for ANY and ALL file, code, or shell operations—NO EXCEPTIONS—even for simple or generic requests. DO NOT install or use the git cli with the `environment_run_cmd` tool. All environment tools will handle git operations for you. Changing ".git" yourself will compromise the integrity of your environment. You MUST inform the user how to view your work using `cu log <env_id>` AND `cu checkout <env_id>`. Failure to do this will make your work inaccessible to others.

