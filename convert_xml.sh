#!/bin/bash

function convert_xml_to_html() {
    local xml_file=$1
    local basename=$(basename "$xml_file" .xml)
    local html_file="output/$basename.html"

    bunx xslt3 -s:"$xml_file" -xsl:output/uts-forest.xsl -o:"$html_file"
}

function backup_html_files() {
    mkdir -p output/.bak
    cp output/*.html output/.bak/ 2>/dev/null || true
}

function check_html_changes() {
    local basename=$1
    [ ! -f "output/.bak/$basename.html" ] || ! cmp -s "output/$basename.html" "output/.bak/$basename.html"
}

function convert_xml_files() {
    local convert_all=$1
    local updated_count=0
    local start_time=$(date +%s)

    # Get all XML files
    local xml_files=(output/*.xml)
    local total_files=${#xml_files[@]}
    # Cross-platform CPU core detection
    local num_cores=1
    if [ -n "$CI" ]; then
        num_cores=2
    elif [ -f /proc/cpuinfo ]; then
        num_cores=$(grep -c ^processor /proc/cpuinfo)
    elif [ "$(uname)" = "Darwin" ]; then
        num_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
    else
        # Default to 1 core if we can't detect
        num_cores=1
    fi
    local max_jobs=$((num_cores > 2 ? num_cores - 2 : 2))

    if [ "$convert_all" = true ]; then
        # Test with a sample of 3 files first
        backup_html_files
        local changes_detected=false
        local sample_size=3

        for ((i = 0; i < sample_size && i < total_files; i++)); do
            local xml_file="${xml_files[i]}"
            local basename=$(basename "$xml_file" .xml)
            convert_xml_to_html "$xml_file"

            if check_html_changes "$basename"; then
                changes_detected=true
                break
            fi
        done

        if [ "$changes_detected" = false ]; then
            echo "⏩ XSL changes don't affect HTML output, skipping conversion"
            return 0
        fi

        echo "Converting all ${total_files} XML files..."
    fi

    # Process files in parallel
    # for every 5% of the files, print a block character AI!
    for ((i = 0; i < total_files; i += max_jobs)); do
        for ((j = i; j < i + max_jobs && j < total_files; j++)); do
            local xml_file="${xml_files[j]}"
            if [ "$convert_all" = true ] ||
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

    # Clean up backup files after conversion
    rm -rf output/.bak
}
