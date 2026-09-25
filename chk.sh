#!/bin/bash
set -eo pipefail

PYTHONDONTWRITEBYTECODE=1 uv run tests/test_ftip_prose.py
uv run check-ftip-prose.py source

if [ -n "$CI" ]; then
    bun install
    bunx biome ci
    # bunx knip
else
    # locally, `bun install` should have been run separately
    bunx biome check --fix # --unsafe
fi
