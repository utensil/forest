import json
import os
import pathlib
import shutil
import subprocess
import sys
from pathlib import Path
# pip install bibtexparser
import bibtexparser

# Get the script directory
script_dir = Path(__file__).resolve().parent
# Set the project root directory
project_root = script_dir

# Set the bib directory
bib_dir = project_root / 'trees' / 'refs'
# Set the bib file name
bib_filename = sys.argv[1] if len(sys.argv) > 1 else 'references'

bib_file = pathlib.Path(bib_dir) / f'{bib_filename}.bib'
csljson_file = pathlib.Path(bib_dir) / f'{bib_filename}.json'

print(f'📚 {bib_file.relative_to(project_root)} -> {csljson_file.relative_to(project_root)}')
# Run the pandoc command
subprocess.run(['pandoc', f'{bib_file}', '-s', '-f', 'biblatex', '-t', 'csljson', '-o', csljson_file], check=True)

# Load the BibTeX file
with open(bib_file, encoding='utf-8') as f:
    bib_db = bibtexparser.load(f)

csljson_file_name = csljson_file.stem

with open(csljson_file, encoding='utf-8') as f:
    references = json.load(f)

# create a directory to store the split files
generated_dir = bib_dir / 'generated'
os.makedirs(generated_dir, exist_ok=True)

TREE_TEMPLATE = r"""
\title{{{title}}}
\date{{{date}}}
{authors}
\taxon{{reference}}

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

print(f'📚 Splitting {csljson_file.relative_to(project_root)}')
csl_file = bib_dir / 'forest.csl'
for i, reference in enumerate(references):
    citekey = reference['id']
    csljson_file_i = generated_dir / f'{citekey}.json'
    tree_file_i = bib_dir / f'{citekey}.tree'
    print(f'📚 {csljson_file_i.relative_to(project_root)} -> {tree_file_i.relative_to(project_root)}')

    bibtex_entry = bib_db.entries_dict[citekey]
    entrydb = bibtexparser.bibdatabase.BibDatabase()
    entrydb.entries = [bibtex_entry]
    original_bibtex = bibtexparser.dumps(entrydb)

    with open(csljson_file_i, 'w', encoding='utf-8') as f:
        # reference['title'] = reference.get('title', '').replace('\n', ' ')
        # reference['title_short'] = reference.get('title', '').split(' ')[0].lower()

        # print(original_bibtex)
        reference['original_bibtex'] = original_bibtex
        json.dump([reference], f)
        f.flush()

    with open(tree_file_i, 'w', encoding='utf-8') as f:
        formatted = TREE_TEMPLATE.format(
            title=reference['title'],
            date=format_date(reference['issued']['date-parts'][0]),
            authors=''.join([f'\\author{{{format_author(author)}}}' for author in reference['author']]),
            original_bibtex=original_bibtex)
        f.write(formatted)
        f.flush()
