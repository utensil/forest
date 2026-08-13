#!/bin/bash

# fail fast for this shell
# set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT="$SCRIPT_DIR"

export TEXINPUTS=.:$PROJECT_ROOT/tex/:
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"
export TZ=UTC

echo "TEXINPUTS=$TEXINPUTS"

# LaTeXize an xml: NOT working yet!

XSLFILE="${2:-article}".xsl

XML_FILE="$1.xml"
TEX_FILE="$1.tex"
AUX_FILE="$1.aux"
PDF_FILE="$1.pdf"

rm "build/$1".* >/dev/null 2>&1 || echo no files to clean

# Forester 5.x outputs XML at output/forest/TREE_ID/index.xml
cp "output/forest/$1/index.xml" "build/$XML_FILE"

# brew install saxon
# bun add xslt3

bunx xslt3 -s:"build/$XML_FILE" -xsl:"assets/$XSLFILE" -o:"build/$TEX_FILE"

# LuaTeX otherwise generates a random PDF trailer ID.  Tie it to the generated
# TeX so equal source renders to identical publication bytes across worktrees.
PDF_ID=$(shasum -a 256 "build/$TEX_FILE" | awk '{print toupper(substr($1, 1, 32))}')
WRAPPER_FILE="$1.lize.tex"
printf '\\pdfvariable trailerid {[<%s> <%s>]}\n\\input{%s}\n' "$PDF_ID" "$PDF_ID" "$TEX_FILE" > "build/$WRAPPER_FILE"

cd build || exit

# UNICOCE_LATEX=xelatex
UNICOCE_LATEX=lualatex

# if environment variable TEC is not set
if [ -z "$TEC" ]; then
    echo "lize.sh| using $UNICOCE_LATEX"
    $UNICOCE_LATEX -halt-on-error -interaction=nonstopmode --shell-escape --jobname="$1" "$WRAPPER_FILE" # >/dev/null # 2>&1
    # https://tex.stackexchange.com/a/295524/75671
    # biber $TEX_FILE
    # We should ignore bibtex errors if it's simply an empty .bib file
    bibtex "$AUX_FILE" >/dev/null 2>&1 || echo "lize.sh| Ignoring bibtex error"
    $UNICOCE_LATEX -halt-on-error -interaction=nonstopmode --shell-escape --jobname="$1" "$WRAPPER_FILE" # >/dev/null # 2>&1
    $UNICOCE_LATEX -halt-on-error -interaction=nonstopmode --shell-escape --jobname="$1" "$WRAPPER_FILE" # >/dev/null # 2>&1
else
    echo "lize.sh| using tectonic"
    tectonic -Z shell-escape-cwd="$(pwd)" --keep-intermediates --keep-logs --outdir "$(pwd)" "$TEX_FILE" >/dev/null # 2>&1
fi

cd ..

cp "build/$PDF_FILE" "output/forest/$PDF_FILE"

echo "lize.sh| Open build/$1.log to see the log."
echo "lize.sh| Open build/$TEX_FILE to see the LaTeX source."
echo "lize.sh| Open output/forest/$PDF_FILE to see the result."

# use ./lize.sh uts-0001 2>&1|grep lize to see a short output
