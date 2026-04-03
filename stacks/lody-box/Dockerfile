# Bun binary — copy from official image to avoid remote install script
FROM oven/bun:1-debian AS bun

FROM node:22-slim

# Copy bun binary from official image (no curl, no unpinned remote script)
COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
ENV PATH="/root/.bun/bin:$PATH"

RUN apt-get update && apt-get install -y \
    git unzip \
    && rm -rf /var/lib/apt/lists/*

# Install all four AI agents via bun (consistent with host-side prep tasks)
RUN bun add -g \
    @anthropic-ai/claude-code \
    @openai/codex \
    @google/gemini-cli \
    lody

WORKDIR /workspace

# Default to bash — run agents explicitly:
#   lody:        docker compose run lody-box lody start
#   claude/codex/gemini: docker exec -it lody-box <agent>
CMD ["bash"]
