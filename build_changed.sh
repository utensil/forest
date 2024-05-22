#!/bin/bash

while IFS= read -r line; do
    # IFS=':' read -ra ADDR <<< "$line"
    # echo "File ${ADDR[0]} changed"
    # if line begins with "other:"
    # if [[ $line == other:* ]]; then
    #     # echo "Other event: $line"
    #     continue
    # fi

    echo "Event: $line"
    ./build.sh
done