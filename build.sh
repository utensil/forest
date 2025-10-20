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
    if [ ! -d "lib/$lib_name" ]; then
        git clone --depth 1 "$url" "lib/$lib_name"
        if [ -n "$hash" ]; then
            (cd "lib/$lib_name" && git fetch --depth 1 origin "$hash" && git checkout "$hash")
        fi
    fi

    # only run wasm-pack build in CI or for `dev.sh`, so other people would not need Rust dependencies
    if [ -n "$CI" ] || [ -n "$UTS_DEV" ]; then
        # Check if pkg directory exists and is not empty
        if [ ! -d "lib/$lib_path/pkg" ] || [ -z "$(ls -A "lib/$lib_path/pkg")" ]; then
            echo "Building WASM package for $lib_name..."
            (cd "lib/$lib_path" && bunx wasm-pack -v build --target web --release . --out-dir pkg || echo -e "\033[0;31mwasm-pack build failed\033[0m")
        else
            echo "Using cached WASM package for $lib_name"
        fi
    else
        # echo warning emoji
        echo "🟡 Skipping wasm-pack build for $lib_name, some notes that used Rust and WASM might not work as epected."
    fi

    cp "lib/$lib_path"/pkg/*.wasm output/forest/
}

function bun_build {
    # don't run `bun install` for `dev.sh`
    if [ -z "$UTS_DEV" ]; then
        bun install
    fi

    mkdir -p output
    prep_wasm wgputoy https://github.com/compute-toys/wgpu-compute-toy.git 3fee2f5d9441aa4c55ea9e7a0b6a1daa21e8e874
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
        elif [[ $FILE == *".ts" || $FILE == *".tsx" ]]; then
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

function build {
    mkdir -p build
    echo "⭐ Rebuilding bun"
    bun_build
    backup_xml_files
    echo "⭐ Rebuilding forest"
    just forest
    show_result

    if [ $? -ne 0 ]; then
        echo -e "\033[0;31mError: Forest build failed.\033[0m"
        exit 1
    fi

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
