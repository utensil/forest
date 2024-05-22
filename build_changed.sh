#!/bin/bash

while IFS= read -r line; do
    IFS=':' read -ra ADDR <<< "$line"
    EVENT="${ADDR[0]}"
    CHANGED_FILE="${ADDR[1]}"
    echo "$EVENT: $CHANGED_FILE"
    if [[ $CHANGED_FILE == *".css" ]] || [[ $CHANGED_FILE == *".js" ]] || [[ $CHANGED_FILE == *".xsl" ]]; then
        echo "🛁 Cleaning up build and output"
        rm -rf build
        rm -rf output
        ./build.sh
    elif [[ $CHANGED_FILE == *".tree" ]] || [[ $CHANGED_FILE == *".tex" ]]; then
        ./build.sh
    else
        echo "🤷 No action for $LINE"
    fi
done