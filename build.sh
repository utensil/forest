#!/bin/bash

function show_result {
  # if return code is zero, then echo "Done" else echo "Failed"
  if [ $? -ne 0 ]; then
    # echo a red "Failed"
    echo -e "\033[0;31mFailed\033[0m"
  else
    # echo a gree "Done"
    echo -e "\033[0;32mDone\033[0m"
  fi
}

function build {
  opam exec -- forester build # --dev
  show_result
}

function lize {
  ./lize.sh spin-0001 2>&1 | grep -F "lize.sh| " |sed -e 's/lize.sh\| //'
  show_result
  ./lize.sh hopf-0001 2>&1 | grep -F "lize.sh| " |sed -e 's/lize.sh\| //'
  show_result
}

echo "⭐ Rebuilding forest"
time build
echo

#if environment variable CI or LIZE is set
if [ -n "$CI" ] || [ -n "$LIZE" ]; then
  echo "⭐ Rebuilding LaTeX"
  time lize
  echo
fi

