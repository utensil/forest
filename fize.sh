#!/bin/bash

# foresterize a tree with LaTeX math

TREE="trees/$1.tree"

# for the file $TREE, replace all string matching regrex \$([^$]+)\$ to #{$1} where $1 is the first match using sed inplace
sed -i '' -E 's/\$([^$]+)\$/#{\1}/g' $TREE
# for the file $TREE, replace all string matching regrex \$\$\n([^$]+)\$\$ to ##{$1} where $1 is the first match using sed inplace
cat $TREE | tr '\n' '\r' | sed -E 's/\$\$([^$]+)\$\$/##{\1}/g' > $TREE.tmp
# for the file $TREE.tmp, replace all string matching \r(.*)\r\r to \r\p{\1}\r\r where $1 is the first match using sed inplace
# sed -i '' -E 's/\r(.*)\r\r/\p{\r\1\r}\r\r/g' $TREE.tmp
cat $TREE.tmp | tr '\r' '\n' > $TREE
rm $TREE.tmp
# for the file $TREE, replace all string \( to #{ using sed inplace
sed -i '' -E 's/\\\(/#\{/g' $TREE
# for the file $TREE, replace all string \) to } using sed inplace
sed -i '' -E 's/\\\)/}/g' $TREE
# for the file $TREE, replace all string \[ to ##{ using sed inplace
sed -i '' -E 's/\\\[/##\{/g' $TREE
# for the file $TREE, replace all string \] to } using sed inplace
sed -i '' -E 's/\\\]/}/g' $TREE
# for the file $TREE, replace \texdef to \refdef using sed inplace
sed -i '' -E 's/\\texdef/\\refdef/g' $TREE

