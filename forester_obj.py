import re
from pathlib import Path

def replace_method_syntax_in_file(file_path):
    """Replace [draw/...] and #draw/... syntax with - in a file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace method definitions [draw/...]
    content = re.sub(r'\[([^/]+)/([^\]]+)\]', r'[\1-\2]', content)
    
    # Replace method calls #draw/...
    content = re.sub(r'#([^/]+)/([^ \t\n\r\f\v]+)', r'#\1-\2', content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def process_files():
    """Process all matching files in the trees directory"""
    for file_path in Path('trees').glob('*g-*.tree'):
        replace_method_syntax_in_file(file_path)

if __name__ == '__main__':
    process_files()
