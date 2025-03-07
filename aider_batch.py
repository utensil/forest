#!/usr/bin/env python

import argparse
import glob
import os
from pathlib import Path

from aider.coders import Coder
from aider.io import InputOutput
from aider.models import Model

def read_file(fname):
    """Read and return file contents, or None if file can't be read"""
    try:
        with open(fname) as f:
            return f.read()
    except Exception as e:
        print(f"Error reading {fname}: {e}")
        return None

def main():
    parser = argparse.ArgumentParser(
        description="Use aider to batch edit a base file using a pattern of input files"
    )
    parser.add_argument("base_file", help="Base file to edit")
    parser.add_argument("pattern", help="Glob pattern to match input files")
    parser.add_argument(
        "--prompt", 
        help="Prompt text or @filename to read prompt from file"
    )
    parser.add_argument(
        "--context", 
        help="Optional context file to include"
    )
    parser.add_argument(
        "--model",
        default="gpt-4",
        help="Model to use (default: gpt-4)"
    )
    args = parser.parse_args()

    # Read prompt from file if specified with @
    if args.prompt.startswith("@"):
        prompt_file = args.prompt[1:]
        prompt = read_file(prompt_file)
        if not prompt:
            return 1
    else:
        prompt = args.prompt

    # Read optional context
    context = ""
    if args.context:
        context = read_file(args.context)
        if context is None:
            return 1
        
    # Create model and coder
    io = InputOutput(yes=True) # Auto-confirm all prompts
    model = Model(args.model)
    
    # Get absolute path of base file
    base_file = os.path.abspath(args.base_file)
    
    # Find all files matching pattern
    matched_files = glob.glob(args.pattern, recursive=True)
    if not matched_files:
        print(f"No files matched pattern: {args.pattern}")
        return 1

    print(f"Processing {len(matched_files)} files...")

    # Process each matched file
    for fname in matched_files:
        print(f"\nProcessing {fname}...")
        
        # Read the input file
        content = read_file(fname)
        if content is None:
            continue

        # Create fresh coder for each file to avoid context buildup
        coder = Coder.create(
            main_model=model,
            io=io,
            fnames=[base_file]
        )

        # Build the full prompt
        full_prompt = prompt
        if context:
            full_prompt = context + "\n\n" + full_prompt
        full_prompt += f"\n\nHere is the content of {fname}:\n\n{content}"

        # Run aider on this file
        result = coder.run(full_prompt, preproc=False)
        
        # Print any response content
        if result:
            print("\nAider response:", result)

    return 0

if __name__ == "__main__":
    exit(main())
