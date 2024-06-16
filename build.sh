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

function show_lize_result {
  # if return code is zero, then echo "Done" else echo "Failed"
  if [ $? -ne 0 ]; then
    # echo a red "Failed"
    echo -e "\033[0;31mFailed\033[0m"
    tail -n 50 build/$1.log

  else
    # echo a gree "Done"
    echo -e "\033[0;32mDone\033[0m"
  fi
  echo "Open build/$1.log to see the log."
  echo "Open build/$1.tex to see the LaTeX source."
  echo "Open output/$1.pdf to see the result."
}

function build {
  opam exec -- forester build # --dev
  show_result
}

function lize {
  ./lize.sh spin-0001 2>&1 > /dev/null
  show_lize_result spin-0001
  ./lize.sh hopf-0001 2>&1 > /dev/null
  show_lize_result hopf-0001
  ./lize.sh ca-0001 2>&1 > /dev/null
  show_lize_result ca-0001
  ./lize.sh tt-0001 2>&1 > /dev/null
  show_lize_result tt-0001
  ./lize.sh math-0001 2>&1 > /dev/null
  show_lize_result math-0001
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

