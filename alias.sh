#!/bin/bash
for recipe in `just --summary`; do
    alias $recipe="just $recipe"
done
echo "✅ aliases initialized: $(just --summary)"
