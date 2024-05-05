#!/bin/bash

# fix paragraph breaks

TREE="trees/$1.tree"

cat $TREE | tr '\n' '\r' > $TREE.ptmp
sed -i '' -E 's/\r\r(.*)\r\r/\r\rp{\1}\r\r/g' $TREE.ptmp
cat $TREE.ptmp | tr '\r' '\n' > $TREE
rm $TREE.ptmp


