#!/bin/bash
TREE_PREFIX=${1:-uts}
opam exec -- forester new --dest=trees --prefix=$TREE_PREFIX
