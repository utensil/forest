#!/bin/bash
TREE_PREFIX=${1:-uts}
FILENAME=$(opam exec -- forester new --dest=trees --prefix=$TREE_PREFIX)
echo $FILENAME

# if templates/$TREE_PREFIX.tree exists
if [ -f templates/$TREE_PREFIX.tree ]; then
    cat templates/$TREE_PREFIX.tree > $FILENAME
else
    cat templates/ag.tree > $FILENAME
fi
