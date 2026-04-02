# lody-box — Sandboxed AI Coding Agents

A Docker sandbox for running AI coding agents ([Lody](https://lody.ai),
[Claude Code](https://docs.anthropic.com/claude-code),
[Codex](https://github.com/openai/codex), and
[Gemini CLI](https://github.com/google-gemini/gemini-cli))
in an isolated environment.

The container defaults to `bash` — all four agents are available via `docker exec` or
`docker compose run`. Start the lody daemon explicitly when needed.

## Why Docker?

Lody is a remote-controlled local execution platform: when you chat via the
lody.ai web UI, the server sends commands to your machine's daemon, which spawns
the underlying agent and executes its tool calls. Docker limits the blast radius:

- **Filesystem** — agents only see what you mount in; host `~/.ssh`, `~/.aws`, etc. are
  out of scope by default
- **Process** — agents cannot inspect or kill host processes
- **Agent auth** — named volumes persist login state across rebuilds without
  touching your host config files

## Setup

1. Copy `.env.in` to `.env` and fill in your tokens/keys:

    ```sh
    cp .env.in .env
    ```

2. Create the workspace directory (or set `WORKSPACE_PATH` in `.env` to an existing path):

    ```sh
    mkdir -p workspace
    # or: put your repos directly under workspace/
    ```

3. Build and start:

    ```sh
    docker compose up -d --build
    ```

4. Auth each agent once (stored in named volumes, survives rebuilds):

    ```sh
    # Lody
    docker exec -it lody-box lody login

    # Claude Code (or set ANTHROPIC_API_KEY in .env instead)
    docker exec -it lody-box claude auth

    # Gemini (or set GEMINI_API_KEY in .env instead)
    docker exec -it lody-box gemini auth

    # Codex — no interactive auth needed when OPENAI_API_KEY is set in .env
    ```

5. Verify:

    ```sh
    docker exec lody-box lody --version
    docker exec lody-box claude --version
    docker exec lody-box codex --version
    docker exec lody-box gemini --version
    ```

## Day-to-day usage

```sh
# Open a shell
docker exec -it lody-box bash

# Start the lody daemon (connects to lody.ai; manages claude and codex agents)
docker compose run lody-box lody start

# Run Claude Code on a repo
docker exec -it lody-box claude --print "explain this codebase"

# Run Codex
docker exec -it lody-box codex "add tests for src/utils.ts"

# Run Gemini (standalone — not managed by the lody daemon)
docker exec -it lody-box gemini "review this PR diff"
```

## Re-auth a single agent

```sh
# Remove just that agent's auth volume, then re-auth
docker volume rm lody-box_claude-auth
docker compose up -d
docker exec -it lody-box claude auth
```

> **Note:** To re-auth lody specifically: `docker volume rm lody-box_lody-auth`, then
> `docker exec -it lody-box lody login`.

## Agents

| Agent | Package | Auth |
|-------|---------|------|
| [Lody](https://lody.ai) | `lody` | `lody login` + `LODY_CLI_TOKEN` |
| [Claude Code](https://docs.anthropic.com/claude-code) | `@anthropic-ai/claude-code` | `claude auth` or `ANTHROPIC_API_KEY` |
| [Codex](https://github.com/openai/codex) | `@openai/codex` | `OPENAI_API_KEY` env var |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | `@google/gemini-cli` | `gemini auth` or `GEMINI_API_KEY` |

> **Lody agent types:** `lody start --cli-types` only accepts `claude` or `codex`. Gemini is
> available in the container but runs standalone — it is not managed by the lody daemon.

## Base image

Runtime base: `node:22-slim` (Debian slim, ~220 MB uncompressed). Node.js is required by all
four agents; bun is used for package management via `bun add -g`.

`oven/bun:1-debian` is used as a **build stage only** to copy the bun binary —
it is not the runtime base, so the ~70 MB overhead doesn't apply. This avoids
the unpinned `curl | bash` install script while keeping `node:22-slim` as the
final image.

## References

- [Lody documentation](https://lody.ai/docs)
- [Claude Code documentation](https://docs.anthropic.com/claude-code)
- [Codex (OpenAI)](https://github.com/openai/codex)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
