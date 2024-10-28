#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["bibtexparser"]
# ///
import json
import os
import pathlib
import shutil
import subprocess
import sys
from pathlib import Path
import bibtexparser
from bibtexparser.bwriter import BibTexWriter, SortingStrategy
import re

BIB_TEX_WRITER = BibTexWriter()
BIB_TEX_WRITER.display_order = [
    'title', 'author', 'year', 'date', 'isbn', 'doi', 'url', 'urldate', 'howpublished',
    'journal', 'journaltitle', 'booktitle', 'edition', 'series',
    'editor', 'volume', 'number', 'pages', 'publisher', 'institution', 'address'
]
BIB_TEX_WRITER.display_order_sorting = SortingStrategy.PRESERVE # ALPHABETICAL_ASC ALPHABETICAL_DESC


# Get the script directory
script_dir = Path(__file__).resolve().parent
# Set the project root directory
project_root = script_dir

# Set the bib directory
tex_dir = project_root / 'tex'
bib_dir = project_root / 'trees' / 'refs'
# Set the bib file name
bib_filename = sys.argv[1] if len(sys.argv) > 1 else 'references'
# create a directory to store the split files
generated_dir = bib_dir / 'generated'
os.makedirs(generated_dir, exist_ok=True)

bib_file = pathlib.Path(tex_dir) / f'{bib_filename}.bib'
csljson_file = generated_dir / f'{bib_filename}.json'

print(f'📚 {bib_file.relative_to(project_root)} -> {csljson_file.relative_to(project_root)}')
# Run the pandoc command
subprocess.run(['pandoc', f'{bib_file}', '-s', '-f', 'biblatex', '-t', 'csljson', '-o', csljson_file], check=True)

# Load the BibTeX file
with open(bib_file, encoding='utf-8') as f:
    bib_db = bibtexparser.load(f)

csljson_file_name = csljson_file.stem

with open(csljson_file, encoding='utf-8') as f:
    references = json.load(f)

TREE_TEMPLATE = r"""% {bib_filenames}
\title{{{title}}}
\date{{{date}}}
{authors}
\taxon{{reference}}
{meta_doi}{meta_external}
\meta{{bibtex}}{{\startverb
{original_bibtex}\stopverb}}
"""

def format_author(author):
    if 'literal' in author:
        return author['literal']
    elif 'given' in author and 'family' in author:
        author_name = []
        author_name.append(author['given'])
        if 'dropping-particle' in author:
            author_name.append(author['dropping-particle'])
        author_name.append(author['family'])
        return ' '.join(author_name)
    else:
        return ''

# format a number with leading zeros
def format_number(number, length=2):
    format_string = "{:0" + str(length) + "}"
    return format_string.format(number)

def format_date(date_parts):
    return '-'.join([format_number(part) for part in date_parts])

def format_doi(reference):
    doi = reference.get('DOI', None)
    return f'\\meta{{doi}}{{{doi}}}\n' if doi else ''

def format_external(reference):
    url = reference.get('URL', None)
    if url is None:
        publisher = reference.get('publisher', None)
        # if publisher is a URL, use regex
        if publisher is not None:
            url = re.search('(https?://[^\s]+)', publisher)
            if url is not None:
                url = url.group(1)
                print(f'🔵 {url}')

    return f'\\meta{{external}}{{{url}}}\n' if url else ''

def parse_frontmatter(line):
    # strip beginning whitespace and %
    line = line.lstrip().lstrip('%').lstrip()
    # try parse it as JSON
    try:
        ret = json.loads(line)
        # check if it's an array
        if isinstance(ret, list):
            return ret
        else:
            return []
    except json.JSONDecodeError:
        return []

# print(f'📚 Splitting {csljson_file.relative_to(project_root)}')
csl_file = bib_dir / 'forest.csl'
for i, reference in enumerate(references):
    citekey = reference['id']
    csljson_file_i = generated_dir / f'{citekey}.json'
    tree_file_i = bib_dir / f'{citekey}.tree'
    print(f'  {csljson_file_i.relative_to(project_root)} -> {tree_file_i.relative_to(project_root)}')

    bibtex_entry = bib_db.entries_dict[citekey]
    entrydb = bibtexparser.bibdatabase.BibDatabase()
    entrydb.entries = [bibtex_entry]
    original_bibtex = bibtexparser.dumps(entrydb, BIB_TEX_WRITER)

    with open(csljson_file_i, 'w', encoding='utf-8') as f:
        # reference['title'] = reference.get('title', '').replace('\n', ' ')
        # reference['title_short'] = reference.get('title', '').split(' ')[0].lower()

        # print(original_bibtex)
        reference['original_bibtex'] = original_bibtex
        json.dump([reference], f)
        f.flush()

    bib_filenames_i = [bib_filename]

    # if tree_file_i exists
    if os.path.exists(tree_file_i):
        # read the first line
        with open(tree_file_i, 'r', encoding='utf-8') as f:
            first_line = f.readline()
            first_line_json = parse_frontmatter(first_line)
            # remove bib_filename from it
            bib_filenames_i = [
                filename for filename in first_line_json
                if filename != bib_filename
            ]
            # add bib_filename to the end of it
            bib_filenames_i.append(bib_filename)
            # sort the list
            bib_filenames_i.sort()

    # detect duplication
    if len(bib_filenames_i) > 1:
        #  {tree_file_i.relative_to(project_root)}:
        print(f'🟡 {bib_filenames_i}')

    formatted = TREE_TEMPLATE.format(
        bib_filenames=json.dumps(bib_filenames_i),
        title=reference['title'],
        date=format_date(reference['issued']['date-parts'][0]),
        meta_doi=format_doi(reference),
        meta_external=format_external(reference),
        authors=''.join([f'\\author{{{format_author(author)}}}' for author in reference['author']]),
        original_bibtex=original_bibtex)

    if tree_file_i.exists():
        with open(tree_file_i, 'r', encoding='utf-8') as f:
            existing = f.read()
            # get the first line
            existing_first_line, existing_rest = existing.split('\n', 1)
            existing_bib_filenames_i = parse_frontmatter(existing_first_line)
            # if it's the same or shorter
            if len(existing_bib_filenames_i) >= len(bib_filenames_i) or set(existing_bib_filenames_i) == set(bib_filenames_i):
                formatted_first_line, formatted_rest = formatted.split('\n', 1)
                if existing_rest == formatted_rest:
                    continue
            # if manually modified, skip
            if 'manual' in existing_bib_filenames_i:
                print(f"🦘Skipping {tree_file_i.relative_to(project_root)} as it's manually modified")
                continue

    with open(tree_file_i, 'w', encoding='utf-8') as f:
        f.write(formatted)
        f.flush()
