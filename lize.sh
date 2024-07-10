#!/bin/bash

# fail fast for this shell
set -e

# LaTeXize an xml: NOT working yet!

XSLFILE="${2:-article}".xsl

XML_FILE="$1.xml"
TEX_FILE="$1.tex"
AUX_FILE="$1.aux"
PDF_FILE="$1.pdf"

rm build/$1.* || echo no files to clean

cp output/$XML_FILE build/$XML_FILE

# brew install saxon

saxon -s:build/$XML_FILE -xsl:assets/$XSLFILE -o:build/$TEX_FILE

cd build

# if environment variable CI is set
if [ -n "$CI" ]; then
    echo "lize.sh| CI is set, using xelatex"
    xelatex -halt-on-error -interaction=nonstopmode --shell-escape $TEX_FILE
    # https://tex.stackexchange.com/a/295524/75671
    # biber $TEX_FILE
    # We should ignore bibtex errors if it's simply an empty .bib file
    bibtex $AUX_FILE || echo "lize.sh| Ignoring bibtex error"
    xelatex -halt-on-error -interaction=nonstopmode --shell-escape $TEX_FILE
    xelatex -halt-on-error -interaction=nonstopmode --shell-escape $TEX_FILE
else
    echo "lize.sh| CI is not set, using tectonic"
    tectonic -Z shell-escape-cwd=`pwd` --keep-intermediates --keep-logs --outdir `pwd` $TEX_FILE
fi

cd ..

cp build/$PDF_FILE output/$PDF_FILE

echo "lize.sh| Open build/$1.log to see the log."
echo "lize.sh| Open build/$TEX_FILE to see the LaTeX source."
echo "lize.sh| Open output/$PDF_FILE to see the result."

# use ./lize.sh math-0001 2>&1|grep lize to see a short output