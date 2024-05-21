#!/bin/bash

function build {
  opam exec -- forester build # --dev
  # if return code is zero, then echo "Done" else echo "Failed"
  if [ $? -ne 0 ]; then
    echo
    # echo a red "Failed"
    echo -e "\033[0;31mFailed\033[0m"
  else
    echo
    # echo a gree "Done"
    echo -e "\033[0;32mDone\033[0m"
  fi
}

echo
echo "Rebuilding forest"
time build
echo

echo
