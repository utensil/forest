#!/bin/bash

# LaTeXize an xml: NOT working yet!

$XML_FILE = $1
$TEX_FILE = ${$XML_FILE%.xml}.tex
$AUX_FILE = ${$XML_FILE%.xml}.aux

# brew install saxon

saxon -s:output/$XML_FILE -xsl:assets/book.xsl -o:output/$TEX_FILE

cd output
pdflatex -halt-on-error -interaction=nonstopmode $TEX_FILE
bibtex $AUX_FILE
pdflatex -halt-on-error -interaction=nonstopmode $TEX_FILE
pdflatex -halt-on-error -interaction=nonstopmode $TEX_FILE