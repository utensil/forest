#!/bin/bash
# TODO: how to make this work without requiring a `source init.sh`
for recipe in `just --summary`; do
    alias $recipe="just $recipe"
done
echo "✅ aliases initialized: $(just --summary)"
