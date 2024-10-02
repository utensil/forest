#!/bin/bash
set -euxo pipefail

# update and regenerate bibliography trees

BIBALL=${BIBALL:-}
if [ -n "$BIBALL" ]; then
    echo update all bib files including the ones in remote repos
    curl --clobber -H 'Cache-Control: no-cache, no-store' https://raw.githubusercontent.com/utensil/blog/main/content/posts/transformer/bib.bib  -o tex/transformer.bib
    curl --clobber -H 'Cache-Control: no-cache, no-store' https://raw.githubusercontent.com/utensil/blog/main/content/posts/math-2024/bib.bib  -o tex/math-2024.bib
    curl --clobber -H 'Cache-Control: no-cache, no-store' https://raw.githubusercontent.com/utensil/blog/main/content/posts/zeon-algebra/bib.bib  -o tex/zeon-algebra.bib
    curl --clobber -H 'Cache-Control: no-cache, no-store' https://raw.githubusercontent.com/utensil/lean-ga/blueprint/blueprint/src/references.bib -o tex/lean-ga.bib
else
    echo update only local bib files
fi

./split_bib.py transformer
./split_bib.py math-2024
./split_bib.py zeon-algebra
# lean-ga should be more updated if duplicated
./split_bib.py lean-ga
# forest overrides external bibs
./split_bib.py forest
