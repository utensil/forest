#!/bin/bash

function convert_xml_to_html() {
    local xml_file=$1
    local basename=$(basename "$xml_file" .xml)
    local html_file="output/$basename.html"

    bunx xslt3 -s:"$xml_file" -xsl:output/uts-forest.xsl -o:"$html_file"
}

function convert_xml_files() {
    local convert_all=$1
    local updated_count=0
    local start_time=$(date +%s)

    # Get all XML files
    local xml_files=(output/*.xml)
    local total_files=${#xml_files[@]}
    local num_cores=$(sysctl -n hw.ncpu)
    local max_jobs=$((num_cores > 2 ? num_cores - 2 : 2))

    if [ "$convert_all" = true ]; then
        echo "Converting all XML files..."
    fi

    # Process files in parallel
    for ((i = 0; i < total_files; i += max_jobs)); do
        for ((j = i; j < i + max_jobs && j < total_files; j++)); do
            local xml_file="${xml_files[j]}"
            if [ "$convert_all" = true ] || \
               ([ -f "output/.bak/$(basename $xml_file)" ] && ! cmp -s "$xml_file" "output/.bak/$(basename $xml_file)"); then
                convert_xml_to_html "$xml_file" &
                ((updated_count++))
            fi
        done
        wait
    done

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "📝 Updated $updated_count HTML file(s) in ${duration}s"
}
