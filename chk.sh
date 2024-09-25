#!/bin/bash
set -eo pipefail

if [ -n "$CI" ]; then
    bun install
    bunx biome ci
    # bunx knip
else
    # locally, `bun install` should have been run separately
    bunx biome check --fix # --unsafe
fi
