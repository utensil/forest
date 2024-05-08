#!/bin/bash

# fail fast for this shell
set -e

# LaTeXize an xml: NOT working yet!

XSLFILE="${2:-book}".xsl

XML_FILE="$1.xml"
TEX_FILE="$1.tex"
AUX_FILE="$1.aux"
PDF_FILE="$1.pdf"

# brew install saxon

saxon -s:output/$XML_FILE -xsl:assets/$XSLFILE -o:output/$TEX_FILE

cd output
# xelatex -halt-on-error -interaction=nonstopmode --shell-escape $TEX_FILE
# bibtex $AUX_FILE
# xelatex -halt-on-error -interaction=nonstopmode --shell-escape $TEX_FILE
# xelatex -halt-on-error -interaction=nonstopmode --shell-escape $TEX_FILE

tectonic -Z shell-escape-cwd=. --keep-intermediates --outdir . $TEX_FILE

echo "Open output/$1.log to see the log."
echo "Open output/$TEX_FILE to see the LaTeX source."
echo "Open output/$PDF_FILE to see the result."