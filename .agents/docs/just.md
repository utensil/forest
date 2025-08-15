# just Task Automation: Best Practices

[`just`](https://just.systems/) is a command runner and task automation tool, used in this repository to manage development, build, and environment tasks. It provides a simple, readable syntax for defining and organizing repeatable commands.

---

## Inspecting Tasks

### Reading justfiles

#### Listing Tasks

Use `just --list` or run the default task to see all available tasks in the repository.

#### Inspecting Task Definitions

Use `just --show <task>` to print the full definition of a task, including dependencies and all recipe lines, before running it.

---

## Task Directory and Working Directory

- Imported tasks (from `dotfiles/*.just`) always run in the root justfile’s directory (`justfile_directory()`).
- Standalone justfiles (e.g., in `stacks/`) run in their own directory by default.
- Use `[no-cd]` if a task must run in the user’s invocation directory instead of the justfile’s directory. See the [just README](https://github.com/casey/just/blob/master/README.md#working-directory) for details.

---

## Writing justfiles

#### Default Task

Always provide a `default:` task that runs `just --list` and any helpful info:

```just
default:
    just --list
```

#### Shebang for Recipes

Start multi-line or complex shell recipes with a shebang unless each line can be run independently in a subshell:

```just
my-task:
    #!/usr/bin/env bash
    echo "Hello from bash"
```

#### Section Comments

Use double-hash comments (`## Section`) to organize related tasks for readability and navigation.

#### Modularization and Imports

Place reusable tasks in `dotfiles/*.just` and import them in the root justfile using `import 'dotfiles/yourfile.just'`.

#### Exports

Use `export` for variables needed in multiple recipes as environment variables:

```just
export PROJECT_ROOT := justfile_directory()
```

#### Parameterized Tasks

Use parameters for flexibility:

```just
build DIR="output":
    ./build.sh {{DIR}}
```

For tasks that forward arbitrary arguments, use a convention like `*PARAMS`:

```just
run *PARAMS:
    cargo run -- {{PARAMS}}
```

#### Environment

Use `set dotenv-load` to automatically load environment variables from `.env` files.

#### Comments

Use `set ignore-comments` to ignore recipe lines beginning with `#`, so just won't print them as an executed line.

---

## Further Reading

- [just README (GitHub)](https://github.com/casey/just/blob/master/README.md)
- [just documentation](https://just.systems/man/en/)

