#!/bin/bash
set -euo pipefail

echo -n "Checking lost notes"

FOUND_LOST_NOTE=0

# for every file *.tree in the trees directory
for f in trees/*.tree; do
    echo -n "."
    # extract the filename without the extension
    FILENAME=$(basename $f .tree)
    # if FILENAME is not included in any files trees/*.tree
    # echo "^\\\\transclude\\{$FILENAME\\}"
    if ! grep -q -E "^\\\\transclude\\{$FILENAME\\}" trees/*.tree; then
        # if "\tag{draft}" is not in the FILENAME
        if ! grep -q -F "\tag{draft}" $f; then
            # if FILENAME is not started with "math-"
            if [[ $FILENAME != math-* && $FILENAME != *-0001 && $FILENAME != *macros && $FILENAME != index && $FILENAME != latex-preamble ]]; then
                # add 1 to FOUND_LOST_NOTE
                FOUND_LOST_NOTE=$((FOUND_LOST_NOTE + 1))
                echo
                echo "trees/$FILENAME.tree might be a lost note"
            fi
        fi
    fi
done

if [[ $FOUND_LOST_NOTE == 0 ]]; then
    echo
fi
echo "Found $FOUND_LOST_NOTE lost note(s)."
