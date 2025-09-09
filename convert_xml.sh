#!/bin/bash
# set -e

OUT_DIR=output/forest
# XSL_FILE=$OUT_DIR/default.xsl
XSL_FILE=$OUT_DIR/uts-forest.xsl

function convert_xml_to_html() {
    local xml_file=$1
    # Extract NOTE_ID from path: $OUT_DIR/NOTE_ID/index.xml
    local note_id=$(basename $(dirname "$xml_file"))
    local html_file="$OUT_DIR/$note_id/index.html"

    # echo "[convert_xml_to_html] xml_file: $xml_file"
    # echo "[convert_xml_to_html] note_id: $note_id"
    # echo "[convert_xml_to_html] html_file: $html_file"
    # echo "[convert_xml_to_html] xsltproc -v -o \"$html_file\" $XSL_FILE \"$xml_file\""

    # bunx xslt3 -s:"$xml_file" -xsl:output/uts-forest.xsl -o:"$html_file"
    # -v
    xsltproc --path $OUT_DIR -o "$html_file" $XSL_FILE "$xml_file"
    # echo "[convert_xml_to_html] Finished xsltproc for $html_file"
    # head -n 20 "$html_file"
}
# AGENT-NOTE: Updated for new forest path structure (input/output under $OUT_DIR/NOTE_ID/)

function backup_html_files() {
    mkdir -p $OUT_DIR/.bak
    # Copy each $OUT_DIR/NOTE_ID/index.html to $OUT_DIR/.bak/NOTE_ID/index.html
    for html_file in $OUT_DIR/*/index.html; do
        note_id=$(basename $(dirname "$html_file"))
        mkdir -p "$OUT_DIR/.bak/$note_id"
        cp -f "$html_file" "$OUT_DIR/.bak/$note_id/index.html" 2>/dev/null || true
    done
}
# AGENT-NOTE: Updated backup logic for forest structure

function check_html_changes() {
    local note_id=$1
    local html_file="$OUT_DIR/$note_id/index.html"
    local bak_file="$OUT_DIR/.bak/$note_id/index.html"
    [ ! -f "$bak_file" ] || ! cmp -s "$html_file" "$bak_file"
}
# AGENT-NOTE: Updated for forest structure (compare $OUT_DIR/NOTE_ID/index.html)

function sample_based_change_detected() {
    local xml_files=("$@")
    local total_files=${#xml_files[@]}
    local sample_size=3
    backup_html_files
    local changes_detected=false
    sample_pids=()
    sample_note_ids=()
    for ((i = 0; i < sample_size && i < total_files; i++)); do
        local xml_file="${xml_files[i]}"
        local note_id=$(basename $(dirname "$xml_file"))
        convert_xml_to_html "$xml_file" &
        sample_pids+=($!)
        sample_note_ids+=("$note_id")
    done
    for pid in "${sample_pids[@]}"; do
        wait "$pid"
    done
    cmp_pids=()
    for note_id in "${sample_note_ids[@]}"; do
        (
            if check_html_changes "$note_id"; then
                touch "$OUT_DIR/.bak/$note_id/changed"
            fi
        ) &
        cmp_pids+=($!)
    done
    for pid in "${cmp_pids[@]}"; do
        wait "$pid"
    done
    for note_id in "${sample_note_ids[@]}"; do
        if [ -f "$OUT_DIR/.bak/$note_id/changed" ]; then
            changes_detected=true
            break
        fi
    done
    find $OUT_DIR/.bak -name changed -delete
    $changes_detected && return 0 || return 1
}
# AGENT-NOTE: Updated for forest structure (sample and change detection)

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
    # echo "[parallel_convert_xml_files] convert_all: $convert_all"
    local max_jobs=$2
    shift 2
    local xml_files=("$@")
    local total_files=${#xml_files[@]}
    local progress=0
    local progress_step=$((total_files / 20)) # 5% intervals
    [ $progress_step -eq 0 ] && progress_step=1
    echo -n "Progress: "
    local updated_file_list="$OUT_DIR/.updated_files"
    : > "$updated_file_list"
    pids=()
    for ((i = 0; i < total_files; i++)); do
        local xml_file="${xml_files[i]}"
        # echo "[parallel_convert_xml_files] Processing: $xml_file"
        (
            local note_id=$(basename $(dirname "$xml_file"))
            local html_file="$OUT_DIR/$note_id/index.html"
            local bak_file="$OUT_DIR/.bak/$note_id/index.html"
            local do_convert=0

            if [ "$convert_all" = true ] || [ -n "$XSL_CHANGED" ] || [ "$changes_detected" = true ]; then
                do_convert=1
            elif [ ! -f "$html_file" ]; then
                do_convert=1
            elif [ "$XSL_FILE" -nt "$html_file" ]; then
                do_convert=1
            fi

            # echo "[parallel_convert_xml_files] note_id: $note_id do_convert: $do_convert"

            if [ $do_convert -eq 1 ]; then
                convert_xml_to_html "$xml_file"
                echo "$note_id" >> "$updated_file_list"
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
# AGENT-NOTE: Updated for forest structure (parallel conversion and progress)


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

    # Get all XML files in $OUT_DIR/*/index.xml
    local xml_files=($OUT_DIR/*/index.xml)
    local total_files=${#xml_files[@]}
    # echo "[convert_xml_files] Found $total_files XML files:"
    # for xml_file in "${xml_files[@]}"; do
        # echo "[convert_xml_files] $xml_file"
    # done
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

    local updated_file_list="$OUT_DIR/.updated_files"
    local updated_count=0
    if [ -f "$updated_file_list" ]; then
        updated_count=$(wc -l < "$updated_file_list")
        rm -f "$updated_file_list"
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "📝 Updated $updated_count HTML file(s) in ${duration}s"

}
# AGENT-NOTE: Updated for forest structure (xml listing and updated files)

