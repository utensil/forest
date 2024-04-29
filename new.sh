#!/bin/bash
TREE_PREFIX=${1:-uts}
FILENAME=$(opam exec -- forester new --dest=trees --prefix=$TREE_PREFIX)
echo $FILENAME
cat templates/texdef.tree > $FILENAME
