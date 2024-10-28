#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///
import sys
import re

# foresterize a tree with LaTeX math

if len(sys.argv) != 2:
    print("Usage: python3 fize.py <tree>")
    sys.exit(1)

TREE = f"trees/{sys.argv[1]}.tree"

with open(TREE, 'r+') as file:
    content = file.read()
    # Fix enumerate and itemize
    content = re.sub(r'\\begin\{enumerate\}', r'\\ol{', content)
    content = re.sub(r'\\end\{enumerate\}', r'}', content)
    content = re.sub(r'\\begin\{itemize\}', r'\\ul{', content)
    content = re.sub(r'\\end\{itemize\}', r'}', content)
    content = re.sub(r'\\item (.*)', r'\\li{\1}', content)
    content = re.sub(r'\\ii (.*)', r'\\li{\1}', content)

    # Convert some LaTeX commands to forester commands
    content = re.sub(r'\\emph\{([^}]*)\}', r'\\em{\1}', content)

    # Replace all line breaks to `\r` to handle multiline replacements
    content.replace('\n', '\r')

    # Replace display math `$$...$$` with `##{...}`
    content = re.sub(r'\$\$([^$]+)\$\$', r'##{\1}', content)

    # Replace inline math `$...$` with `#{...}`
    content = re.sub(r'\$([^$]+)\$', r'#{\1}', content)

    # Replace LaTeX block openning with a forester block openning, plus a paragraph openning
    # Particularly, this introduce a line break after the block openning
    content = re.sub(r'\\texdef\{([^\}]*)\}\{([^\}]*)\}\{', r'\\refdef{\1}{\2}{\n\n\\p{', content)
    content = re.sub(r'\\texnote\{([^\}]*)\}\{([^\}]*)\}\{', r'\\refnote{\1}{\2}{\n\n\\p{', content)
    content = re.sub(r'\\minitex\{', r'{\n\n\\p{', content)

    # Before the line containing \refdef, skip; after the line, replace \r\r with }\r\r\\p{
    content = content.split('\n')
    skip = True
    for i in range(len(content)):
        if re.search(r'\\(refdef|refnote)', content[i]):
            skip = False
            continue
        if not skip:
            content[i] = content[i].replace('\r\r', '}\r\r\\p{')
    content = '\n'.join(content)

    # Replace an ending } with } }, the inserted } is to close the paragraph
    content = re.sub(r'}\s*$', r'}\r\r}\r', content)

    # Replace \( with #{   -- obsolete
    # content = re.sub(r'\\\(', r'#\{', content)

    # Replace \) with }   -- obsolete
    # content = re.sub(r'\\\)', r'}', content)

    # Replace \[ with ##{   -- obsolete
    # content = re.sub(r'\\\[', r'##\{', content)

    # Replace \] with }  -- obsolete
    # content = re.sub(r'\\\]', r'}', content)

    # Replace \texdef with \refdef
    content = re.sub(r'\\texdef', r'\\refdef', content)

    # Replace the file content
    file.seek(0)
    file.write(content)
    file.truncate()
