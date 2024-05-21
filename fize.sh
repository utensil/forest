#!/bin/bash

# foresterize a tree with LaTeX math

TREE="trees/$1.tree"

# for the file $TREE, replace all string matching regrex \$([^$]+)\$ to #{$1} where $1 is the first match using sed inplace
sed -i '' -E 's/\$([^$]+)\$/#{\1}/g' $TREE
# for the file $TREE, replace all string matching regrex \$\$\n([^$]+)\$\$ to ##{$1} where $1 is the first match using sed inplace
cat $TREE | tr '\n' '\r' | sed -E 's/\$\$([^$]+)\$\$/##{\1}/g' > $TREE.tmp
# 1. \texdef{}{}{ -> \refdef{}{}{\r\\p{
sed -i '' -E 's/\\texdef\{([^\}]*)\}\{([^\}]*)\}\{/\\refdef\{\1\}\{\2\}\{\n\\p\{/g' $TREE.tmp
# 2. before the line containing \refdef, skip; after the line, replace \r\r -> }\r\r\\p{ 
awk 'BEGIN {skip=1} {if ($0 ~ /\\refdef/) {skip=0;print $0} else if (skip==1) {print $0} else { gsub(/\r\r/,"}\r\r\\p{", $0); print $0} }' $TREE.tmp > $TREE.tmp2
# 3. }\s*$ -> }}
sed -i '' -E 's/\}\s*$/\}\}\r/g' $TREE.tmp2
cat $TREE.tmp2 | tr '\r' '\n' > $TREE
rm $TREE.tmp*
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

