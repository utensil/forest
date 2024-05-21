#!/bin/bash

rm -rf build
rm -rf output
./build.sh

fswatch -l 200 -o trees/ assets/ | while read num ; \
  do \
    ./build.sh
  done
