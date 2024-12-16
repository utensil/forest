#!/bin/bash
set -eo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT="$SCRIPT_DIR"

function backup_xml_files() {
    echo "⭐ Backing up XML files"
    mkdir -p output/.bak
    cp output/*.xml output/.bak/ 2>/dev/null || true
}

function relative_to_project_root() {
    local target=$1
    local common_part=$PROJECT_ROOT
    local back=

    while [[ "${target#$common_part}" == "${target}" ]]; do
        common_part=$(dirname $common_part)
        back="../${back}"
    done

    echo "${back}${target#$common_part/}"
}

while IFS= read -r line; do
    IFS=':' read -ra ADDR <<<"$line"
    EVENT="${ADDR[0]}"
    CHANGED_FILE="${ADDR[1]}"
    # echo emoji for information
    echo "ℹ️ $EVENT: $CHANGED_FILE"
    CHANGED_FILE_BASENAME=$(basename $CHANGED_FILE)
    # get the dirname of the changed file
    CHANGED_FILE_DIRNAME=$(basename $(dirname $CHANGED_FILE))
    # # get the file name relative to the project root
    CHANGED_FILE_RELATIVE=$(relative_to_project_root $CHANGED_FILE)
    # echo "📂$CHANGED_FILE_DIRNAME"
    if [[ $CHANGED_FILE == *".css" ]]; then
        just css $CHANGED_FILE_RELATIVE
    # this should cover .js .ts .jsx .tsx
    elif [[ $CHANGED_FILE_DIRNAME == "bun" ]]; then
        just js $CHANGED_FILE_RELATIVE
    elif [[ $CHANGED_FILE == *".xsl" ]]; then
        just copy $CHANGED_FILE_RELATIVE
    elif [[ $CHANGED_FILE == *".tree" ]]; then
        backup_xml_files
        just forest
    elif [[ $CHANGED_FILE == *".tex" ]]; then
        # even with full rebuild, updates to preambles are NOT reflected
        # ./build.sh
        just forest
    elif [[ $CHANGED_FILE == *".bib" ]]; then
        just bib
    elif [[ $CHANGED_FILE == *".glsl" ]]; then
        just glsl $CHANGED_FILE_RELATIVE
    elif [[ $CHANGED_FILE == *".typ" ]]; then
        just typ $CHANGED_FILE_RELATIVE
    elif [[ $CHANGED_FILE == *".domain" ]] || [[ $CHANGED_FILE == *".style" ]] || [[ $CHANGED_FILE == *".substance" ]] || [[ $CHANGED_FILE == *".trio.json" ]]; then
        just penrose $CHANGED_FILE_RELATIVE
    else
        echo "🤷 No action for $LINE"
    fi

    # Trigger live reload after processing each file
    (mkdir -p build/live && echo -n $CHANGED_FILE_RELATIVE >build/live/updated_file.txt)
done

touch build/live/trigger.txt

# Post-process: Convert HTML files for tree or XSL changes
updated_count=0
start_time=$(date +%s)

if [[ $CHANGED_FILE == *".xsl" ]]; then
    # Convert all XML files when XSL changes
    for xml_file in output/*.xml; do
        basename=$(basename "$xml_file" .xml)
        echo "Converting $basename.xml due to XSL change..."
        bunx xslt3 -s:"$xml_file" -xsl:assets/uts-forest.xsl -o:"output/$basename.html"
        ((updated_count++))
    done
elif [[ $CHANGED_FILE == *".tree" ]]; then
    # Only compare and convert changed XML files for tree changes
    for xml_file in output/*.xml; do
        if [ -f "output/.bak/$(basename $xml_file)" ] && ! cmp -s "$xml_file" "output/.bak/$(basename $xml_file)"; then
            basename=$(basename "$xml_file" .xml)
            echo "Converting updated $basename.xml to HTML..."
            bunx xslt3 -s:"$xml_file" -xsl:assets/uts-forest.xsl -o:"output/$basename.html"
            ((updated_count++))
        fi
    done
fi

end_time=$(date +%s)
duration=$((end_time - start_time))
echo "📝 Updated $updated_count HTML file(s) in ${duration}s"

