#!/usr/bin/env uv run --python 3.11 --with aider-chat
"""
Batch Processing Script for Aider

This script uses aider to process multiple input files and edit a base file according to a prompt.

Usage:
    python aider_batch.py base_file pattern [options]

Arguments:
    base_file       The file to be edited by aider
    pattern         Glob pattern to match input files (e.g., "inputs/*.py")

Options:
    --prompt TEXT   Prompt text or @filename to read prompt from file
    --context FILE  Optional context file to include
    --model MODEL   Model to use (default: gpt-4)

Examples:
    1. Basic usage with direct prompt:
        python aider_batch.py app.py "tests/*.py" --prompt "Add error handling to app.py based on these test cases"

    2. Using a prompt file:
        python aider_batch.py app.py "examples/*.py" --prompt @prompt.txt

    3. With context and specific model:
        python aider_batch.py app.py "data/*.json" --prompt @prompt.txt --context setup.txt --model gpt-4-turbo

Notes:
    - Requires aider-chat to be installed (pip install aider-chat)
    - OpenAI API key must be set in environment
    - Creates a fresh aider session for each input file
    - Auto-confirms all prompts
    - Processes files one at a time to avoid context pollution
"""

import argparse
import glob
import os
import random
import time
from pathlib import Path
import sys

from aider.coders import Coder
from aider.io import InputOutput
from aider.models import Model


def infer_model():
    """Infer the model from environment variables

    This function determines which model to use based on environment variables:
    - OPENAI_API_BASE: The API endpoint to use (can be OpenAI-compatible servers)
        - localhost:15432 -> Local copilot-more server (needs OPENAI_API_MODEL set)
        etc.

    - OPENAI_API_KEY: The API key for authentication
        - Some local servers accept any dummy key like 'sk-dummy'
        - Each service has its own key format:
            - OpenAI: sk-...
            etc.

    Returns:
        str: The inferred model name with provider prefix (e.g. 'openai/claude-3.5-sonnet')
    """
    api_base = os.getenv("OPENAI_API_BASE")
    model_id = os.getenv("OPENAI_API_MODEL", "claude-3.5-sonnet")
    model_name = f"openai/{model_id}"

    print(f"Using API endpoint: {api_base}")
    print(f"Using model: {model_name}")
    return model_name


def read_file(fname):
    """Read and return file contents, or None if file can't be read"""
    try:
        with open(fname) as f:
            return f.read()
    except Exception as e:
        print(f"Error reading {fname}: {e}")
        return None


def main():
    # Infer model first
    model_name = infer_model()

    parser = argparse.ArgumentParser(
        description="Use aider to batch edit a base file using a pattern of input files"
    )
    parser.add_argument("base_file", help="Base file to edit")
    parser.add_argument("pattern", help="Glob pattern to match input files")
    parser.add_argument(
        "--prompt", help="Prompt text or @filename to read prompt from file"
    )
    parser.add_argument("--context", help="Optional context file to include")
    parser.add_argument(
        "--model", help="Model to use (defaults to environment settings)"
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

    # Override inferred model if specified in args
    if args.model:
        model_name = args.model
        print(f"Overriding with specified model: {model_name}")

    # Create model and coder
    io = InputOutput(yes=True)  # Auto-confirm all prompts
    model = Model(model_name)

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

        # Random sleep between 1-5 seconds
        sleep_time = random.uniform(1, 5)
        print(f"Waiting {sleep_time:.1f} seconds...")
        time.sleep(sleep_time)

        # Read the input file
        content = read_file(fname)
        if content is None:
            continue

        # Create fresh coder for each file to avoid context buildup
        coder = Coder.create(main_model=model, io=io, fnames=[base_file])

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
