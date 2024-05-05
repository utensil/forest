#!/bin/bash

./build.sh

fswatch -o trees/ assets/ | while read num ; \
  do \
    ./build.sh
  done
