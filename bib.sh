#!/bin/bash

# update and regenerate bibliography trees

curl --clobber -H 'Cache-Control: no-cache, no-store' https://raw.githubusercontent.com/utensil/blog/main/content/posts/transformer/bib.bib  -o trees/refs/transformer.bib
curl --clobber -H 'Cache-Control: no-cache, no-store' https://raw.githubusercontent.com/utensil/blog/main/content/posts/math-2024/bib.bib  -o trees/refs/math-2024.bib
curl --clobber -H 'Cache-Control: no-cache, no-store' https://raw.githubusercontent.com/utensil/blog/main/content/posts/zeon-algebra/bib.bib  -o trees/refs/zeon-algebra.bib
curl --clobber -H 'Cache-Control: no-cache, no-store' https://raw.githubusercontent.com/utensil/lean-ga/blueprint/blueprint/src/references.bib -o trees/refs/lean-ga.bib

python split_bib.py transformer
python split_bib.py math-2024
python split_bib.py zeon-algebra
python split_bib.py lean-ga
python split_bib.py forest



