#!/bin/bash

# if just is not installed
if ! command -v just &> /dev/null; then
  # install just
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
fi

for recipe in `just --summary`; do
    alias $recipe="just $recipe"
done
echo "✅ aliases initialized: $(just --summary)"
