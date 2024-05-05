#!/bin/bash

echo
echo "Rebuilding forest"
rm -rf output
time opam exec -- forester build # --dev
echo
# if return code is zero, then echo "Done" else echo "Failed"
if [ $? -ne 0 ]; then
  echo "Failed"
else
  echo "Done"
fi
echo
