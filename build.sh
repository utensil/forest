#!/bin/bash
set -eo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT="$SCRIPT_DIR"

export TEXINPUTS=.:$PROJECT_ROOT/tex/:

echo "TEXINPUTS=$TEXINPUTS"

function show_result {
  # if return code is zero, then echo "Done" else echo "Failed"
  if [ $? -ne 0 ]; then
    # echo a red "Failed"
    echo -e "\033[0;31mFailed\033[0m"
  else
    # echo a gree "Done"
    echo -e "\033[0;32mDone\033[0m"
  fi
}

function show_lize_result {
  # if return code is zero, then echo "Done" else echo "Failed"
  if [ $? -ne 0 ]; then
    # echo a red "Failed"
    echo -e "\033[0;31mFailed\033[0m"    
    tail -n 50 build/$1.log
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
    lib_path=${3:-$lib_name}
    if [ ! -d "lib/$lib_name" ]; then
        git clone --depth 1 $url lib/$lib_name
    fi

    if [ ! -d "lib/$lib_path/pkg" ]; then
        (cd lib/$lib_path && bunx wasm-pack build --target web --release . --out-dir pkg)
    fi

    cp lib/$lib_path/pkg/*.wasm output/
}

function bun_build {
    if [ -n "$CI" ]; then
        bun install
    fi

    mkdir -p output

    prep_wasm wgputoy https://github.com/compute-toys/wgpu-compute-toy.git
    prep_wasm egglog https://github.com/egraphs-good/egglog.git egglog/web-demo
    # failed: 
    # prep_wasm nalgebra https://github.com/dimforge/nalgebra

    # for each files in the directory `bun`, run bun build
    for FILE in $(ls -1 bun); do
        # if the file extension is .css
        if [[ $FILE == *".css" ]]; then
            echo "🚀 lightningcss"
            bunx lightningcss --minify --bundle --targets '>= 0.25%' bun/$FILE -o output/$FILE
        else
            bun run ./bun_build.js bun/$FILE
            # bun build bun/$FILE --outdir output
        fi
    done
}

function copy_extra_assets {
    mkdir -p output/shader/
    cp -f assets/shader/*.glsl output/shader/
    # ls output/shader/

    cp node_modules/@myriaddreamin/typst-ts-web-compiler/pkg/typst_ts_web_compiler_bg.wasm output/
    cp node_modules/@myriaddreamin/typst-ts-renderer/pkg/typst_ts_renderer_bg.wasm output/
    # ls output/*.wasm

    cp node_modules/ginac-wasm/dist/ginac.wasm output/

}

function build {
  mkdir -p build
  echo "⭐ Rebuilding bun"
  bun_build
  echo "⭐ Rebuilding forest"
  opam exec -- forester build # 2>&1 > build/forester.log # --dev
  show_result
  # echo "⭐ Copying assets"
  copy_extra_assets

  # echo "Open build/forester.log to see the log."
}

function lize {
  ./lize.sh spin-0001 2>&1 > /dev/null
  show_lize_result spin-0001
  ./lize.sh hopf-0001 2>&1 > /dev/null
  show_lize_result hopf-0001
  ./lize.sh ca-0001 2>&1 > /dev/null
  show_lize_result ca-0001
  ./lize.sh tt-0001 2>&1 > /dev/null
  show_lize_result tt-0001
  ./lize.sh uts-000C 2>&1 > /dev/null
  show_lize_result uts-000C
#   ./lize.sh uts-0001 2>&1 > /dev/null
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

