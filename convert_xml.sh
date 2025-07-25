#!/bin/bash

function convert_xml_to_html() {
    local xml_file=$1
    local basename=$(basename "$xml_file" .xml)
    local html_file="output/$basename.html"

    # bunx xslt3 -s:"$xml_file" -xsl:output/uts-forest.xsl -o:"$html_file"
    xsltproc -o "$html_file" output/uts-forest.xsl "$xml_file"
}

function backup_html_files() {
    mkdir -p output/.bak
    cp output/*.html output/.bak/ 2>/dev/null || true
}

function check_html_changes() {
    local basename=$1
    [ ! -f "output/.bak/$basename.html" ] || ! cmp -s "output/$basename.html" "output/.bak/$basename.html"
}

function sample_based_change_detected() {
    local xml_files=("$@")
    local total_files=${#xml_files[@]}
    local sample_size=3
    backup_html_files
    local changes_detected=false
    sample_pids=()
    sample_basenames=()
    for ((i = 0; i < sample_size && i < total_files; i++)); do
        local xml_file="${xml_files[i]}"
        local basename=$(basename "$xml_file" .xml)
        convert_xml_to_html "$xml_file" &
        sample_pids+=($!)
        sample_basenames+=("$basename")
    done
    for pid in "${sample_pids[@]}"; do
        wait "$pid"
    done
    cmp_pids=()
    for basename in "${sample_basenames[@]}"; do
        (
            if check_html_changes "$basename"; then
                touch "output/.bak/$basename.changed"
            fi
        ) &
        cmp_pids+=($!)
    done
    for pid in "${cmp_pids[@]}"; do
        wait "$pid"
    done
    for basename in "${sample_basenames[@]}"; do
        if [ -f "output/.bak/$basename.changed" ]; then
            changes_detected=true
            break
        fi
    done
    rm -f output/.bak/*.changed
    $changes_detected && return 0 || return 1
}

function update_progress_bar() {
    local i=$1
    local progress=$2
    local progress_step=$3
    local new_progress=$((i / progress_step))
    while [ $progress -lt $new_progress ] && [ $progress -lt 20 ]; do
        echo -n "█"
        ((progress++))
    done
    return $progress
}

function parallel_convert_xml_files() {
    local convert_all=$1
    local max_jobs=$2
    shift 2
    local xml_files=("$@")
    local total_files=${#xml_files[@]}
    local progress=0
    local progress_step=$((total_files / 20)) # 5% intervals
    [ $progress_step -eq 0 ] && progress_step=1
    echo -n "Progress: "
    local updated_file_list="output/.updated_files"
    : > "$updated_file_list"
    pids=()
    for ((i = 0; i < total_files; i++)); do
        local xml_file="${xml_files[i]}"
        (
            local basename=$(basename "$xml_file" .xml)
            local html_file="output/$basename.html"
            local bak_file="output/.bak/$basename.html"
            local do_convert=0

            if [ "$convert_all" = true ] && [ -n "$XSL_CHANGED" ] && [ "$changes_detected" = true ]; then
                do_convert=1
            elif [ ! -f "$html_file" ]; then
                do_convert=1
            elif [ "output/uts-forest.xsl" -nt "$html_file" ]; then
                do_convert=1
            fi

            if [ $do_convert -eq 1 ]; then
                convert_xml_to_html "$xml_file"
                echo "$basename" >> "$updated_file_list"
                exit 0
            fi
            exit 1
        ) &
        pids+=($!)
        if [ "${#pids[@]}" -ge "$max_jobs" ]; then
            wait "${pids[0]}"
            pids=("${pids[@]:1}")
        fi

        update_progress_bar $i $progress $progress_step
        progress=$?
    done
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    echo # New line after progress bar
}


function detect_max_jobs() {
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
    echo "$max_jobs"
}

function convert_xml_files() {
    local convert_all=$1
    local start_time=$(date +%s)

    # Get all XML files
    local xml_files=(output/*.xml)
    local total_files=${#xml_files[@]}
    local max_jobs=$(detect_max_jobs)
    echo "Max jobs: $max_jobs"

    if [ "$convert_all" = true ]; then
        if [ -n "$XSL_CHANGED" ]; then
            if ! sample_based_change_detected "${xml_files[@]}"; then
                echo "⏩ XSL changes don't affect HTML output, skipping conversion"
                return 0
            fi
        fi
        echo "Converting all ${total_files} XML files..."
    fi

    parallel_convert_xml_files "$convert_all" "$max_jobs" "${xml_files[@]}"

    local updated_file_list="output/.updated_files"
    local updated_count=0
    if [ -f "$updated_file_list" ]; then
        updated_count=$(wc -l < "$updated_file_list")
        rm -f "$updated_file_list"
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "📝 Updated $updated_count HTML file(s) in ${duration}s"

    cleanup_backup_files
}


function cleanup_backup_files() {
    rip output/.bak
}

