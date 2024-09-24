#!/bin/bash
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT="$SCRIPT_DIR"

function remove_output_file {
    echo "🚨removing output/$1"
    rm output/$1
}

while IFS= read -r line; do
    IFS=':' read -ra ADDR <<< "$line"
    EVENT="${ADDR[0]}"
    CHANGED_FILE="${ADDR[1]}"
    # echo emoji for information
    echo "ℹ️$EVENT: $CHANGED_FILE"
    CHANGED_FILE_BASENAME=$(basename $CHANGED_FILE)
    # get the dirname of the changed file
    CHANGED_FILE_DIRNAME=$(basename $(dirname $CHANGED_FILE))
    # # get the file name relative to the project root
    # CHANGED_FILE_RELATIVE=$(realpath --relative-to=$PROJECT_ROOT $CHANGED_FILE)
    # echo "📂$CHANGED_FILE_DIRNAME"
    if [[ $CHANGED_FILE == *".css" ]] || [[ $CHANGED_FILE == *".js" ]]; then
        # remove_output_file $CHANGED_FILE_BASENAME
        ./build.sh
    elif [[ $CHANGED_FILE == *".xsl" ]]; then
        remove_output_file $CHANGED_FILE_BASENAME
        ./build.sh
    elif [[ $CHANGED_FILE == *".tree" ]]; then
        # remove_output_file $CHANGED_FILE_BASENAME
        ./build.sh
    elif [[ $CHANGED_FILE == *".tex" ]]; then
        ./build.sh
    elif [[ $CHANGED_FILE == *".bib" ]]; then
        ./bib.sh
    elif [[ $CHANGED_FILE == *".glsl" ]]; then
        mkdir -p output/shader/
        cp -f assets/shader/* output/shader/
    elif [[ $CHANGED_FILE == *".typ" ]]; then
        mkdir -p output/shader/
        cp -f assets/typst/* output/typst/
    elif [[ $CHANGED_FILE == *".domain" ]] || [[ $CHANGED_FILE == *".style" ]] || [[ $CHANGED_FILE == *".substance" ]] || [[ $CHANGED_FILE == *".trio.json" ]]; then
        mkdir -p output/penrose/
        cp -f assets/penrose/* output/penrose/
    elif [[ $CHANGED_FILE_DIRNAME == "bun" ]]; then
        ./build.sh
    else
        echo "🤷 No action for $LINE"
    fi
    (mkdir -p build/live && realpath --relative-to=$PROJECT_ROOT $CHANGED_FILE > build/live/updated_file.txt && touch build/live/trigger.txt)
done