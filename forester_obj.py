import re
from pathlib import Path
from typing import List, Tuple
import sys
from termcolor import colored

def find_method_syntax_in_content(content: str) -> Tuple[List[str], List[str]]:
    """Find all method definitions and calls in content"""
    # Match method definitions like [draw/something] or [draw/sb/sth]
    def_pattern = r'\[([a-zA-Z0-9_-]+)/([a-zA-Z0-9_/-]+)\]'
    definitions = re.findall(def_pattern, content)
    
    # Match method calls like #draw/something or #draw/sb/sth
    call_pattern = r'#([a-zA-Z0-9_-]+)/([a-zA-Z0-9_/-]+)'
    calls = re.findall(call_pattern, content)
    
    return definitions, calls

def replace_method_syntax(content: str) -> str:
    """Replace method syntax with dashes in content"""
    # Replace definitions [draw/something] -> [draw-something]
    content = re.sub(r'\[([a-zA-Z0-9_-]+)/([a-zA-Z0-9_/-]+)\]', 
                    lambda m: f'[{m.group(1)}-{m.group(2).replace("/", "-")}]', 
                    content)
    
    # Replace calls #draw/something -> #draw-something
    content = re.sub(r'#([a-zA-Z0-9_-]+)/([a-zA-Z0-9_/-]+)',
                    lambda m: f'#{m.group(1)}-{m.group(2).replace("/", "-")}',
                    content)
    
    return content

def process_file(file_path: Path, dry_run: bool = True) -> None:
    """Process a single file, showing changes in dry-run mode"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        definitions, calls = find_method_syntax_in_content(content)
        
        if not definitions and not calls:
            print(colored(f"No methods found in {file_path}", 'yellow'))
            return
            
        print(colored(f"\nProcessing {file_path}:", 'blue'))
        print(colored(f"Found {len(definitions)} definitions and {len(calls)} calls", 'cyan'))
        
        for prefix, method in definitions:
            old = f'[{prefix}/{method}]'
            new = f'[{prefix}-{method.replace("/", "-")}]'
            print(f"Definition: {colored(old, 'red')} -> {colored(new, 'green')}")
        
        for prefix, method in calls:
            old = f'#{prefix}/{method}'
            new = f'#{prefix}-{method.replace("/", "-")}'
            print(f"Call: {colored(old, 'red')} -> {colored(new, 'green')}")
        
        if not dry_run:
            new_content = replace_method_syntax(content)
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(colored("File updated", 'green'))
        else:
            print(colored("Dry run - no changes made", 'yellow'))
            
    except Exception as e:
        print(colored(f"Error processing {file_path}: {str(e)}", 'red'))

def process_files(dry_run: bool = True) -> None:
    """Process all matching files in the trees directory"""
    for file_path in Path('trees').glob('*g-*.tree'):
        process_file(file_path, dry_run)

if __name__ == '__main__':
    dry_run = '--apply' not in sys.argv
    print(colored(f"Running in {'dry-run' if dry_run else 'apply'} mode", 
                 'magenta' if dry_run else 'green'))
    process_files(dry_run)
