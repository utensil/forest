#!/bin/bash
set -eo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT="$SCRIPT_DIR"

export TEXINPUTS=.:$PROJECT_ROOT/tex/:

echo "TEXINPUTS=$TEXINPUTS"

source convert_xml.sh

function relative_to_project_root() {
    local target=$1
    local common_part=$PROJECT_ROOT
    local back=

    while [[ "${target#"$common_part"}" == "${target}" ]]; do
        common_part=$(dirname "$common_part")
        back="../${back}"
    done

    echo "${back}${target#"$common_part"/}"
}

while IFS= read -r line; do
    IFS=':' read -ra ADDR <<<"$line"
    EVENT="${ADDR[0]}"
    CHANGED_FILE="${ADDR[1]}"
    # echo emoji for information
    echo "ℹ️ $EVENT: $CHANGED_FILE"
    CHANGED_FILE_BASENAME=$(basename "$CHANGED_FILE")
    # get the dirname of the changed file
    CHANGED_FILE_DIRNAME=$(basename "$(dirname "$CHANGED_FILE")")
    # # get the file name relative to the project root
    CHANGED_FILE_RELATIVE=$(relative_to_project_root "$CHANGED_FILE")
    # echo "📂$CHANGED_FILE_DIRNAME"
    if [[ $CHANGED_FILE == *".css" ]]; then
        just css "$CHANGED_FILE_RELATIVE"
    # this should cover .js .ts .jsx .tsx
    elif [[ $CHANGED_FILE_DIRNAME == "bun" ]] && [[ $CHANGED_FILE == *".ts" ]]; then
        just js "$CHANGED_FILE_RELATIVE"
    elif [[ $CHANGED_FILE == *".xsl" ]]; then
        just copy "$CHANGED_FILE_RELATIVE"
    elif [[ $CHANGED_FILE == *".tree" ]]; then
        just forest
        # only convert the modified tree's xml to html
        # do not take affected trees into account, for now
        convert_xml_to_html "./output/forest/${CHANGED_FILE_BASENAME%.*}/index.xml"
    elif [[ $CHANGED_FILE == *".tex" ]]; then
        # even with full rebuild, updates to preambles are NOT reflected
        # ./build.sh
        just forest
    elif [[ $CHANGED_FILE == *".bib" ]]; then
        just bib
    elif [[ $CHANGED_FILE == *".glsl" ]]; then
        just glsl "$CHANGED_FILE_RELATIVE"
    elif [[ $CHANGED_FILE == *".typ" ]]; then
        just typ "$CHANGED_FILE_RELATIVE"
    elif [[ $CHANGED_FILE == *".domain" ]] || [[ $CHANGED_FILE == *".style" ]] || [[ $CHANGED_FILE == *".substance" ]] || [[ $CHANGED_FILE == *".trio.json" ]]; then
        just penrose "$CHANGED_FILE_RELATIVE"
    else
        echo "🤷 No action for $line"
    fi

    # Trigger live reload after processing each file
    (mkdir -p build/live && echo -n "$CHANGED_FILE_RELATIVE" >build/live/updated_file.txt)
done

touch build/live/trigger.txt

# Post-process: Convert HTML files for tree or XSL changes
if [[ $CHANGED_FILE == *".xsl" ]]; then
    XSL_CHANGED=1 convert_xml_files true
# elif [[ $CHANGED_FILE == *".tree" ]]; then
    # convert_xml_files true 
fi

