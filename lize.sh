#!/bin/bash

# LaTeXize an xml: NOT working yet!

XML_FILE="$1.xml"
TEX_FILE="$1.tex"
AUX_FILE="$1.aux"
PDF_FILE="$1.pdf"

# brew install saxon

saxon -s:output/$XML_FILE -xsl:assets/book.xsl -o:output/$TEX_FILE

cd output
pdflatex -halt-on-error -interaction=nonstopmode $TEX_FILE
bibtex $AUX_FILE
pdflatex -halt-on-error -interaction=nonstopmode $TEX_FILE
pdflatex -halt-on-error -interaction=nonstopmode $TEX_FILE

echo "Open output/$TEX_FILE to see the LaTeX source."
echo "Open output/$PDF_FILE to see the result."