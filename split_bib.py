import json
import os
import pathlib
import shutil
import subprocess
import sys
from pathlib import Path

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

csljson_file_name = csljson_file.stem

with open(csljson_file, encoding='utf-8') as f:
    references = json.load(f)

# create a directory to store the split files
csljson_files = bib_dir / 'csljson_files'
os.makedirs(csljson_files, exist_ok=True)

print(f'📚 Splitting {csljson_file.relative_to(project_root)}')
csl_file = bib_dir / 'forest.csl'
for i, reference in enumerate(references):
    citekey = reference.get('id', f'{csljson_file_name}_{i}')
    csljson_file_i = csljson_files / f'{citekey}.json'
    tree_file_i = csljson_files / f'{citekey}.tree'

    with open(csljson_file_i, 'w', encoding='utf-8') as f:
        # replace all line breaks to a space
        reference['title'] = reference.get('title', '').replace('\n', ' ')
        reference['title_short'] = reference.get('title', '').split(' ')[0]
        json.dump([reference], f)
        f.flush()

    print(f'📚 {csljson_file_i.relative_to(project_root)} -> {tree_file_i.relative_to(project_root)}')
    subprocess.run(['pandoc', '--citeproc', '-f', 'csljson', csljson_file_i, f'--csl={csl_file}', '-s', '-t', 'plain', '-o', tree_file_i], check=True)
