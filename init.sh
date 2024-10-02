#!/bin/bash
set -eo

# # I'm experimenting using warp as my terminal
# # if warp is not installed
# # if path /Applications/Warp.app/ not exists
# if [ ! -d "/Applications/Warp.app" ]; then
#     # install warp
#     if [[ "$OSTYPE" == "darwin"* ]]; then
#         brew install --cask warp
#         echo "CMD+, then search for terminal, specify External: Osx Exec to Warp.app"
#     fi
# fi

# if bun is not installed
if ! command -v bun &> /dev/null; then
  # install bun
  curl -fsSL https://bun.sh/install | bash
fi

# if just is not installed
if ! command -v just &> /dev/null; then
  # install just
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
fi

# TODO: how to make this work without requiring a `source init.sh`
for recipe in `just --summary`; do
    alias $recipe="just $recipe"
done
echo "✅ aliases initialized: $(just --summary)"
