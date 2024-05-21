#!/bin/bash

rm -rf build
rm -rf output
./build.sh

# -l 200
fswatch -r -o trees | while read num ; \
  do \
    ./build.sh 2>&1|grep -v "texmf-dist"
  done
