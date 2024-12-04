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

    # Convert math first
    content = re.sub(r'\$\$([^$]+)\$\$', r'##{\1}', content)
    content = re.sub(r'\$([^$]+)\$', r'#{\1}', content)

    # Convert LaTeX commands to forester commands
    content = re.sub(r'\\emph\{([^}]*)\}', r'\\em{\1}', content)
    content = re.sub(r'\\texdef\{([^\}]*)\}\{([^\}]*)\}\{', r'\\refdef{\1}{\2}{\n\n\\p{', content)
    content = re.sub(r'\\texnote\{([^\}]*)\}\{([^\}]*)\}\{', r'\\refnote{\1}{\2}{\n\n\\p{', content)
    content = re.sub(r'\\minitex\{', r'{\n\n\\p{', content)

    # Fix enumerate and itemize
    content = re.sub(r'\\begin\{enumerate\}', r'\\ol{', content)
    content = re.sub(r'\\end\{enumerate\}', r'}', content)
    content = re.sub(r'\\begin\{itemize\}', r'\\ul{', content)
    content = re.sub(r'\\end\{itemize\}', r'}', content)
    content = re.sub(r'\\item (.*)', r'\\li{\1}', content)
    content = re.sub(r'\\ii (.*)', r'\\li{\1}', content)

    # Fix line endings and brace structure
    content = re.sub(r'}\s*$', r'}\n\n}\n', content)

    # Replace the file content
    file.seek(0)
    file.write(content)
    file.truncate()
