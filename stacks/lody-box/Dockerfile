# Bun binary — copy from official image to avoid remote install script
FROM oven/bun:1-debian AS bun

FROM node:22-slim

# Copy bun binary from official image (no curl, no unpinned remote script)
COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
ENV PATH="/root/.bun/bin:$PATH"

RUN apt-get update && apt-get install -y \
    git unzip curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install all four AI agents via bun (consistent with host-side prep tasks)
RUN bun add -g \
    @anthropic-ai/claude-code \
    @openai/codex \
    @google/gemini-cli \
    lody

WORKDIR /workspace

# Entrypoint restores agent configs that live outside named volumes
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Default to bash — run agents explicitly:
#   lody:        docker compose run lody-box lody start
#   claude/codex/gemini: docker exec -it lody-box <agent>
CMD ["bash"]
