#!/bin/bash

# fail fast for this shell
set -e

# LaTeXize an xml: NOT working yet!

XSLFILE="${2:-book}".xsl

XML_FILE="$1.xml"
TEX_FILE="$1.tex"
AUX_FILE="$1.aux"
PDF_FILE="$1.pdf"

cp output/$XML_FILE build/$XML_FILE

# brew install saxon

saxon -s:build/$XML_FILE -xsl:assets/$XSLFILE -o:build/$TEX_FILE

cd build
xelatex -halt-on-error -interaction=nonstopmode --shell-escape $TEX_FILE
bibtex $AUX_FILE
xelatex -halt-on-error -interaction=nonstopmode --shell-escape $TEX_FILE
xelatex -halt-on-error -interaction=nonstopmode --shell-escape $TEX_FILE

# tectonic -Z shell-escape-cwd=. --keep-intermediates --outdir . $TEX_FILE

cd ..

cp build/$PDF_FILE output/$PDF_FILE

echo "Open build/$1.log to see the log."
echo "Open build/$TEX_FILE to see the LaTeX source."
echo "Open output/$PDF_FILE to see the result."