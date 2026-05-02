import 'dotfiles/config.just'
import 'dotfiles/term.just'
import 'dotfiles/editor.just'
import 'dotfiles/audit.just'
import 'dotfiles/llm.just'
import 'dotfiles/archived.just'
import 'dotfiles/os.just'
import 'dotfiles/lang.just'
import 'dotfiles/box.just'
import 'dotfiles/backup.just'
import 'dotfiles/file.just'
import 'dotfiles/forge.just'
import 'dotfiles/web.just'

export PROJECT_ROOT := justfile_directory()

default:
    just --list
    @echo '💡 To initialize just aliases: source alias.sh'

## Forester build

new +PARAMS:
    ./new.sh {{PARAMS}}

hn +PARAMS:
    hx `just new {{PARAMS}}`

init: prep
    #!/usr/bin/env bash
    bun install
    just thm

# should run `just init` first
#
# Build forest
build:
    ./build.sh

dev:
    ./dev.sh

lize:
    ./lize.sh

fize:
    ./fize.py

thm:
    ./thm.sh

prep:
    ./prep.sh

prep-bib:
    @echo "pyenv shell 3.11"
    @echo "pip3 install bibtexparser"

bib:
    ./bib.sh

glsl SOURCE:
    mkdir -p output/forest/shader/
    cp -f {{SOURCE}} output/forest/shader/

css SOURCE:
    # ln -s {{justfile_directory()}}/assets/images bun/images || true
    bun build --target=browser --minify --outfile=output/forest/{{file_name(SOURCE)}} {{SOURCE}}
    rm bun/images
    # blocks on
    # - [fix: Use correct MIME type for CSS files in Bun.build outputs](https://github.com/oven-sh/bun/pull/21849)
    # - [Allow relative assets in CSS that don't exist · Issue #22725 · oven-sh/bun](https://github.com/oven-sh/bun/issues/22725)
    # bun run bun_build.ts {{SOURCE}}
    # bunx --bun lightningcss-cli --minify --bundle --targets '>= 0.25%' {{SOURCE}} -o output/forest/{{file_name(SOURCE)}}
    # bunx postcss -o output/{{file_name(SOURCE)}} {{SOURCE}}

js SOURCE:
    bun run bun_build.ts {{SOURCE}}

forest:
    opam exec -- forester build # 2>&1 > build/forester.log # --dev

copy SOURCE:
    -rm output/{{file_name(SOURCE)}} > /dev/null 2>&1
    cp -f {{SOURCE}} output/forest/

typ SOURCE:
    mkdir -p output/typst/
    cp -f {{SOURCE}} output/forest/typst/

penrose SOURCE:
    mkdir -p output/penrose/
    cp -f {{SOURCE}} output/forest/penrose/

fix-thm:
    #!/usr/bin/env bash
    # mv output/default.xsl output/default.xsl.bak || true
    cp -f assets/*.xsl output/forest/
    cp -f assets/uts-forest.xsl output/forest/default.xsl
    # cp -f every file/dir in output except the dir forest
    for file in output/*; do
        if [ -d "$file" ] && [ "$(basename "$file")" != "forest" ]; then
            cp -rf "$file" output/forest/
        elif [ -f "$file" ]; then
            cp -f "$file" output/forest/
        fi
    done

assets:
    #!/usr/bin/env bash
    echo "⭐ Copying assets"
    mkdir output/forest/ 2>/dev/null

    mkdir -p output/forest/shader/
    cp -f assets/shader/*.glsl output/forest/shader/
    cp -f assets/*.xsl output/forest/
    cp -f assets/*.html output/forest/
    cp -f output/forest/uts-forest.xsl output/forest/default.xsl

    cp -rf assets/typst output/forest/
    cp -rf assets/vendor output/forest/
    cp -rf assets/penrose output/forest/
    cp -rf assets/images output/forest/
    cp -f assets/*.html output/forest/
    cp -f assets/fonts/*.woff output/forest/
    # ls output/shader/

    # cp node_modules/@myriaddreamin/typst-ts-web-compiler/pkg/typst_ts_web_compiler_bg.wasm output/
    # cp node_modules/@myriaddreamin/typst-ts-renderer/pkg/typst_ts_renderer_bg.wasm output/
    # ls output/*.wasm

    # cp node_modules/ginac-wasm/dist/ginac.wasm output/

envs:
    #!/usr/bin/env bash
    echo "PROJECT_ROOT: $PROJECT_ROOT"

## Lint

chk:
    ./chk.sh

pre-push:
    just chk

# run 'just pre-push' before every push
# This will run 'just pre-push' before every push, and may block pushes if checks fail, run 'just unprep-push' to disable
#
# Set up Git pre-push hook
prep-push:
    #!/usr/bin/env bash
    echo "Setting up Git pre-push hook..."
    echo "This will run 'just pre-push' before every 'git push'"
    echo "If checks fail, the push will be blocked"
    echo "Run 'just unprep-push' to remove this hook if needed"
    echo ""

    cat > .git/hooks/pre-push << 'EOF'
    #!/bin/sh

    # Git pre-push hook to run just pre-push
    # This will run before every git push

    echo "Running pre-push checks..."

    # Run just pre-push
    if ! just pre-push; then
        echo "Pre-push checks failed. Push aborted."
        exit 1
    fi

    echo "Pre-push checks passed."
    exit 0
    EOF

    chmod +x .git/hooks/pre-push
    echo "✅ Git pre-push hook installed successfully"
    echo "Now 'git push' will automatically run 'just pre-push' first"

# Remove Git pre-push hook
unprep-push:
    #!/usr/bin/env bash
    if [ -f .git/hooks/pre-push ]; then
        rm .git/hooks/pre-push
        echo "✅ Git pre-push hook removed"
        echo "Pushes will no longer run automatic checks"
    else
        echo "ℹ️  No pre-push hook found - nothing to remove"
    fi

prep-shellcheck:
    which shellcheck || brew install shellcheck

shellcheck:
    shellcheck *.sh

proselint FILE="":
    #!/usr/bin/env bash
    # Fuzzy find FILE and pass it to proselint
    if [[ -n "{{FILE}}" ]]; then
        uvx proselint "{{FILE}}"
    else
        local file
        file=$(fzf --height 40% --reverse --preview 'bat --color=always {}' --preview-window right:60%)
        if [[ -n "$file" ]]; then
            uvx proselint "$file"
        fi
    fi

# Supported languages: https://topiary.tweag.io/book/reference/language-support.html
# e.g. OCaml, Bash, TOML
# used by https://git.sr.ht/~jonsterling/ocaml-forester
#
prep-topiary:
    which topiary || cargo install topiary-cli

# https://dprint.dev/
#
prep-dprint:
    which dprint || brew install dprint

# The format is too massive, wait until it's really needed one day
#
check-dprint:
    dprint check --list-different

# https://www.html-tidy.org/
#
prep-tidy:
    brew install tidy-html5

## Enrich contents

# Inspired by https://github.com/Ranchero-Software/NetNewsWire/issues/978#issuecomment-1320911427
#
rss-stars FOR="forest":
    #!/usr/bin/env bash
    cd ~/Library/Containers/com.ranchero.NetNewsWire-Evergreen/Data/Library/Application\ Support/NetNewsWire/Accounts/2_iCloud
    if [ "{{FOR}}" = "linkwarden" ]; then
        # Output all columns for linkwarden import
        sqlite3 DB.sqlite3 '.mode json' 'select a.*, s.* from articles a join statuses s on a.articleID = s.articleID where s.starred = 1 order by s.dateArrived' | jq -c '.[]'
    else
        # Default: only output minimal fields
        sqlite3 DB.sqlite3 '.mode json' 'select a.*, s.* from articles a join statuses s on a.articleID = s.articleID where s.starred = 1 order by s.dateArrived' | jq -r '.[]|{title, url, externalURL, datePublished, dateArrived, uniqueID}'
    fi


rd2lw RAINDROP_FILE *PARAMS="--days 1":
    #!/usr/bin/env bash
    ./rss2linkwarden.py {{RAINDROP_FILE}} | ./linkwarden_import.py {{PARAMS}}

rss2linkwarden *PARAMS="--days 7":
    #!/usr/bin/env bash
    # Export starred RSS links and calls Linkwarden API to import
    just rss-stars "linkwarden" | ./linkwarden_import.py {{PARAMS}}

rss2wallabag *PARAMS="--days 7":
    #!/usr/bin/env bash
    # Export starred RSS links and convert to Linkwarden/Wallabag import format
    just rss-stars "linkwarden" | ./rss2wallabag.py {{PARAMS}}

rss2pocket *PARAMS="--days 7":
    #!/usr/bin/env bash
    # Export starred RSS links and convert to Pocket/Readeck import format as a zip
    mkdir -p output
    just rss-stars "linkwarden" | ./rss2pocket.py {{PARAMS}} > output/part_000000.csv

stars *PARAMS="--days 7":
    just rss-stars|./stars.py {{PARAMS}}

til:
    ./til.py --reset && ./til.py

# relies on GITHUB_ACCESS_TOKEN
#
gh2md REPO OUTPUT *PARAMS="--no-prs":
    #!/usr/bin/env bash
    GITHUB_ACCESS_TOKEN=$(gh auth token) uvx gh2md --idempotent {{PARAMS}} {{REPO}} {{OUTPUT}}
    # https://github.com/mattduck/gh2md/issues/39
    # docker run --rm -it -e GITHUB_ACCESS_TOKEN=$(gh auth token) dockerproxy.net/library/python:3.11.2 bash -c 'pip install gh2md && gh2md --idempotent {{REPO}} {{OUTPUT}}'

