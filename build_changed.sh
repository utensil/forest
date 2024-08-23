#!/bin/bash

while IFS= read -r line; do
    IFS=':' read -ra ADDR <<< "$line"
    EVENT="${ADDR[0]}"
    CHANGED_FILE="${ADDR[1]}"
    # echo emoji for information
    echo "ℹ️$EVENT: $CHANGED_FILE"
    CHANGED_FILE_BASENAME=$(basename $CHANGED_FILE)
    # get the dirname of the changed file
    CHANGED_FILE_DIRNAME=$(basename $(dirname $CHANGED_FILE))
    echo "📂$CHANGED_FILE_DIRNAME"
    echo "🚨removing output/$CHANGED_FILE_BASENAME"
    rm output/$CHANGED_FILE_BASENAME

    if [[ $CHANGED_FILE == *".css" ]] || [[ $CHANGED_FILE == *".js" ]]; then
        ./build.sh
    elif [[ $CHANGED_FILE == *".xsl" ]]; then
        ./build.sh
    elif [[ $CHANGED_FILE == *".tree" ]] || [[ $CHANGED_FILE == *".tex" ]]; then
        ./build.sh
    elif [[ $CHANGED_FILE == *".glsl" ]]; then
        mkdir -p output/shader/
    elif [[ $CHANGED_FILE_DIRNAME == "bun" ]]; then
        ./build.sh
    else
        echo "🤷 No action for $LINE"
    fi
done