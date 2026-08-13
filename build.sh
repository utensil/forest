#!/bin/bash
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT="$SCRIPT_DIR"

export TEXINPUTS=.:$PROJECT_ROOT/tex/:

echo "TEXINPUTS=$TEXINPUTS"

function show_result {
    ret_code=$?
    # if return code is zero, then echo "Done" else echo "Failed"
    if [ $ret_code -ne 0 ]; then
        # echo a red "Failed"
        echo -e "\033[0;31mFailed\033[0m"
    else
        # echo a gree "Done"
        echo -e "\033[0;32mDone\033[0m"
    fi

    return $ret_code
}

function show_lize_result {
    # if return code is zero, then echo "Done" else echo "Failed"
    if [ $? -ne 0 ]; then
        # echo a red "Failed"
        echo -e "\033[0;31mFailed\033[0m"
        tail -n 50 "build/$1.log"
        echo "open build/$1.log to see the log."

    else
        # echo a gree "Done"
        echo -e "\033[0;32mDone\033[0m"
    fi
    echo "Open build/$1.log to see the log."
    echo "Open build/$1.tex to see the LaTeX source."
    echo "Open output/$1.pdf to see the result."
}

function prep_wasm {
    mkdir -p lib
    lib_name=$1
    url=$2
    hash=$3
    lib_path=${4:-$lib_name}
    local hash_file="lib/$lib_path/pkg/.commit_hash"
    local needs_build=false

    if [ ! -d "lib/$lib_name/.git" ]; then
        # No git repo (stale pkg-only cache restore or first run) — clone fresh
        rm -rf "lib/$lib_name"
        git clone --depth 1 "$url" "lib/$lib_name"
        if [ -n "$hash" ]; then
            (cd "lib/$lib_name" && git fetch --depth 1 origin "$hash" && git checkout "$hash")
        fi
        needs_build=true
    elif [ -n "$hash" ] && [ "$(cd "lib/$lib_name" && git rev-parse HEAD)" != "$hash" ]; then
        # Repo exists but pinned to wrong commit
        (cd "lib/$lib_name" && git fetch --depth 1 origin "$hash" && git checkout "$hash")
        needs_build=true
    fi

    if [ ! -d "lib/$lib_path/pkg" ] || [ -z "$(ls -A "lib/$lib_path/pkg")" ]; then
        needs_build=true
    elif [ ! -f "$hash_file" ] || [ "$(cat "$hash_file")" != "$hash" ]; then
        needs_build=true
    fi

    # only run wasm-pack build in CI or for `dev.sh`, so other people would not need Rust dependencies
    if [ -n "$CI" ] || [ -n "$UTS_DEV" ]; then
        if [ "$needs_build" = "true" ]; then
            echo "Building WASM package for $lib_name..."
            (cd "lib/$lib_path" && bunx wasm-pack -v build --target web --release . --out-dir pkg || echo -e "\033[0;31mwasm-pack build failed\033[0m")
            [ -d "lib/$lib_path/pkg" ] && echo "$hash" > "$hash_file"
        else
            echo "Using cached WASM package for $lib_name"
        fi
    else
        echo "🟡 Skipping wasm-pack build for $lib_name, some notes that used Rust and WASM might not work as epected."
    fi

    cp "lib/$lib_path"/pkg/*.wasm output/forest/
}

function bun_build {
    # don't run `bun install` for `dev.sh`
    if [ -z "$UTS_DEV" ]; then
        bun install --frozen-lockfile
    fi

    mkdir -p output/forest
    prep_wasm wgputoy https://github.com/compute-toys/wgpu-compute-toy.git 60d0bec4bd912a54d5049f2c28c1bd6a0916e5ec
    prep_wasm egglog https://github.com/egraphs-good/egglog.git 8d9b10ec712106b21d10b7bf45d10c0f9d1d09c7 egglog/web-demo
    prep_wasm rhaiscript https://github.com/rhaiscript/playground 9fa80661bc9eb69363ac86879826dcd8ccb604af
    # failed:
    # prep_wasm nalgebra https://github.com/dimforge/nalgebra

    # for each files in the directory `bun`, run bun build
    for FILE in $(ls -1 bun); do
        # if the file extension is .css
        if [[ $FILE == *".css" ]]; then
            echo "🚀 lightningcss"
            just css "bun/$FILE"
            # check result
            # EXIT_CODE=$?
            # if [ $EXIT_CODE -ne 0 ]; then
            #     echo "🚨 lightningcss failed with $EXIT_CODE"
            #     exit $EXIT_CODE
            # fi
        elif [[ $FILE == *".ts" || $FILE == *".tsx" || $FILE == *".jsx" ]]; then
            just js "bun/$FILE"
            # bun build bun/$FILE --outdir output
        fi
    done

}

function build_ssr {
    echo "⭐ Rebuilding SSR assets"
    echo >build/ssr.log
    bunx roger trios assets/penrose/*.trio.json -o output 1>>build/ssr.log 2>>build/ssr.log
}

function backup_xml_files() {
    echo "⭐ Backing up XML files"
    mkdir -p output/.bak
    cp output/*.xml output/.bak/ 2>/dev/null || true
}

function needs_update() {
    local xml_file=$1
    local html_file=$2
    local backup_file="output/.bak/$(basename "$xml_file")"

    # If HTML doesn't exist, needs update
    if [ ! -f "$html_file" ]; then
        return 0
    fi

    # If backup doesn't exist (first run), needs update
    if [ ! -f "$backup_file" ]; then
        return 0
    fi

    # Compare current XML with backup
    if ! cmp -s "$xml_file" "$backup_file"; then
        return 0
    fi

    # Check if XSL template is newer than HTML file
    if [ "assets/html.xsl" -nt "$html_file" ]; then
        return 0
    fi

    return 1
}

source convert_xml.sh

function backup_html_before_forester() {
    echo "⭐ Backing up HTML files before forester build"
    local backup_dir="build/.html-bak"
    rm -rf "$backup_dir"
    mkdir -p "$backup_dir"
    for html_file in output/forest/*/index.html; do
        [ -f "$html_file" ] || continue
        local note_id=$(basename $(dirname "$html_file"))
        mkdir -p "$backup_dir/$note_id"
        cp -f "$html_file" "$backup_dir/$note_id/index.html" 2>/dev/null || true
    done
}

function restore_html_after_forester() {
    echo "⭐ Restoring HTML files over forester redirect stubs"
    local backup_dir="build/.html-bak"
    local restored=0
    for bak_file in "$backup_dir"/*/index.html; do
        [ -f "$bak_file" ] || continue
        local note_id=$(basename $(dirname "$bak_file"))
        local html_file="output/forest/$note_id/index.html"
        # Only restore if the current HTML is a redirect stub
        if [ -f "$html_file" ] && grep -q 'meta.*http-equiv.*refresh.*index\.xml' "$html_file" 2>/dev/null; then
            cp -f "$bak_file" "$html_file"
            ((restored++))
        fi
    done
    rm -rf "$backup_dir"
    echo "  Restored $restored HTML files over redirect stubs"
}

function remove_forester_debug_trees() {
    # AGENT-NOTE: Forester 5.0 writes source-like debug files beside public pages.
    local debug_tree_count
    debug_tree_count=$(find output/forest -type f -name index.tree | wc -l | tr -d ' ')
    if [ "$debug_tree_count" -gt 0 ]; then
        echo "⭐ Removing $debug_tree_count Forester debug tree file(s) from public output"
        find output/forest -type f -name index.tree -delete
    fi

    # Earlier builds wrote duplicate HTML backups into the publish tree.
    if [ -d output/forest/.html-bak ]; then
        echo "⭐ Removing stale HTML backup files from public output"
        rm -rf output/forest/.html-bak
    fi
}

function write_root_redirect() {
    # AGENT-NOTE: Forest publishes its home tree through the configured absolute site path.
    local site_url home_tree target_path
    site_url=$(sed -nE 's/^url = "https?:\/\/[^/]+([^\"]*)"/\1/p' forest.toml | head -1)
    home_tree=$(sed -nE 's/^home = "([^\"]+)"/\1/p' forest.toml | head -1)
    target_path="${site_url%/}/${home_tree}/"

    if [ -z "$site_url" ] || [ -z "$home_tree" ]; then
        echo "Error: forest.toml must define forest.url and forest.home" >&2
        exit 1
    fi

    printf '<!DOCTYPE html>\n<html>\n  <head>\n    <meta http-equiv="refresh" content="0;url=%s" />\n    <meta charset="utf-8" />\n  </head>\n</html>\n' "$target_path" > output/forest/index.html
}

function build {
    mkdir -p build
    echo "⭐ Rebuilding bun"
    bun_build
    backup_xml_files
    backup_html_before_forester
    echo "⭐ Rebuilding forest"
    just forest
    show_result

    if [ $? -ne 0 ]; then
        echo -e "\033[0;31mError: Forest build failed.\033[0m"
        exit 1
    fi

    restore_html_after_forester
    remove_forester_debug_trees
    write_root_redirect

    # Check if index.xml was generated
    # if [ ! -f "output/index.xml" ]; then
    #     echo -e "\033[0;31mError: index.xml not found in output directory. Forest build likely failed.\033[0m"
    #     exit 1
    # fi
    just assets
    # if the env var UTS_DEV is not set
    # if [ -z "$UTS_DEV" ]; then
    convert_xml_files true
    # fi
    show_result
    #   build_ssr
    #   show_result
    # echo "Open build/forester.log to see the log."
}

function lize {
    ./lize.sh spin-0001 # >/dev/null # 2>&1
    show_lize_result spin-0001
    ./lize.sh hopf-0001 # >/dev/null # 2>&1
    show_lize_result hopf-0001
    ./lize.sh ca-0001 # >/dev/null # 2>&1
    show_lize_result ca-0001
    ./lize.sh fgap-0001 # >/dev/null # 2>&1
    show_lize_result fgap-0001
    ./lize.sh fcap-0001 # >/dev/null # 2>&1
    show_lize_result fcap-0001
    ./lize.sh tt-0001 # >/dev/null # 2>&1
    show_lize_result tt-0001
    ./lize.sh uts-000C # >/dev/null # 2>&1
    show_lize_result uts-000C
    #   ./lize.sh uts-0001 > /dev/null 2>&1
    #   show_lize_result uts-0001
}

time build
echo

#if environment variable CI or LIZE is set
if [ -n "$CI" ] || [ -n "$LIZE" ]; then
    echo "⭐ Rebuilding LaTeX"
    time lize
    echo
fi
