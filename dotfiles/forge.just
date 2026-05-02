## Git

prep-ssh-agent:
    #!/usr/bin/env bash
    set -e

    # Check if SSH config has agent settings
    if ! grep -q "AddKeysToAgent yes" ~/.ssh/config 2>/dev/null; then
        echo "Setting up SSH config..."
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        if [ ! -f ~/.ssh/config ]; then
            touch ~/.ssh/config
        fi
        echo "" >> ~/.ssh/config
        echo "Host *" >> ~/.ssh/config
        echo "  AddKeysToAgent yes" >> ~/.ssh/config
        echo "  UseKeychain yes" >> ~/.ssh/config
        echo "  IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
        chmod 600 ~/.ssh/config
    fi

    # Start SSH agent if not running
    if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l &>/dev/null; then
        echo "Starting SSH agent..."
        eval "$(ssh-agent -s)"
    fi

    # Add key if not already added
    if ! ssh-add -l | grep -q "id_ed25519"; then
        echo "Adding SSH key to agent..."
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519
    fi

    echo "SSH agent ready. Keys loaded:"
    ssh-add -l

prep-sshpass:
    which sshpass || brew install hudochenkov/sshpass/sshpass

prep-git:
    #!/usr/bin/env bash
    which git || brew install git
    which gh || brew install gh
    # list the current settings
    git config --list
    if [ -z "$(git config --global user.name)" ]; then
        printf "Enter your name: "
        read name
        git config --global user.name "$name"
    fi
    if [ -z "$(git config --global user.email)" ]; then
        printf "Enter your email: "
        read email
        git config --global user.email "$email"
    fi
    git config --global --unset credential.helper
    git config --global credential.helper "store --file ~/.git-credentials"

    git config --global pull.rebase true
    # https://blog.buenzli.dev/rust-for-linux-first-contrib/#git-gud
    # Automatically squash fixup/squash commits during rebase
    git config --global rebase.autoSquash true
    # Stash uncommitted changes before rebase and reapply afterward
    git config --global rebase.autoStash true
    # Preserve merge commits instead of flattening them
    git config --global rebase.rebaseMerges true
    # Update branch refs pointing to rebased commits (useful for stacked changes)
    git config --global rebase.updateRefs true
    # Enable Reuse Recorded Resolution (remember conflict resolutions)
    git config --global rerere.enabled true
    # Automatically stage rerere-resolved files
    git config --global rerere.autoupdate true

    gh auth status || gh auth login
    gh auth setup-git
    echo 'Remember to run `just prep-delta` for better lazygit experience'

prep-delta:
    which delta || brew install git-delta
    git config --global core.pager "delta"
    git config --global interactive.diffFilter "delta --color-only"
    # use n and N to move between diff sections
    git config --global delta.navigate true
    git config --global delta.dark true
    git config --global merge.conflictStyle zdiff3
    # https://git-scm.com/docs/git-diff#Documentation/git-diff.txt---color-movedmode
    # git config --global diff.colorMoved dimmed_zebra
    git config --global diff.colorMovedWs allow-indentation-change
    mkdir -p ~/.config/lazygit
    cp -f .lazygit.yml ~/.config/lazygit/config.yml

prep-resolve:
    which mergiraf || brew install mergiraf
    # https://mergiraf.org/usage.html
    git config --global merge.conflictStyle|grep zdiff3
    jj config list --include-defaults merge-tools | grep mergiraf

resolve:
    jj status && jj resolve --tool mergiraf

git PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && lazygit {{PARAMS}}

prep-gitu:
    which gitu || cargo install gitu --locked

# [NOTE] If modified, test with prep-gtsh
#
clone USER REPO:
    #!/usr/bin/env bash
    mkdir -p ~/projects
    FULL_REPO={{USER}}/{{REPO}}
    DIR=~/projects/{{REPO}}
    if [ ! -d $DIR/.git ]; then
        git clone https://github.com/$FULL_REPO $DIR
    else
        (cd $DIR && git pull) || true
    fi

clone-conf CONF USER REPO:
    #!/usr/bin/env bash
    mkdir -p ~/projects
    FULL_REPO={{USER}}/{{REPO}}
    DIR=~/.config/{{CONF}}
    if [ ! -d $DIR ]; then
        git clone https://github.com/$FULL_REPO $DIR
    elif [ -d $DIR/.git ]; then
        (cd $DIR && git pull) || true
    else
        rip $DIR
        just clone-conf {{CONF}} {{USER}} {{REPO}}
    fi

link-conf CONF:
    ln -s {{justfile_directory()}}/dotfiles/.config/{{CONF}} ~/.config/{{CONF}}

# -w to open in browser
#
actions PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && gh workflow view {{PARAMS}}

prep-date:
    which git-backdate || (curl https://raw.githubusercontent.com/rixx/git-backdate/main/git-backdate > /usr/local/bin/git-backdate && chmod +x /usr/local/bin/git-backdate)
    which gdate || brew install coreutils

date: prep-date
    #!/usr/bin/env bash
    BEGIN_DATE=$(gdate -d "3 days ago" +%Y-%m-%d)
    END_DATE=$(gdate -d "today" +%Y-%m-%d)
    echo "Rewriting history to distribute commits between ${BEGIN_DATE} and ${END_DATE}"
    git backdate origin/main "${BEGIN_DATE}..${END_DATE}" --no-business-hours

prep-gitlog:
    which serie || brew install lusingander/tap/serie

# ? for help
# <Tab>  Open refs list
# <Alt-Down> <Alt-j>  Go to parent
# Vim-like keybindings
#
gitlog:
    serie

prep-zizmor:
    which zizmor || brew install zizmor

lint-gh *PARAMS : prep-zizmor
    zizmor {{PARAMS}} .github/workflows

# # Frequently used jj command alias
#
# ## Edits
#
# l - log (there is always a dirty change @, could be empty)
# n <revset> - create a new change based on <revset> which could be a short change id, a bookmark, and defaults to @ (working copy)
# ci - use builtin diff editor to choose what to commit, use text editor to edit commit message
# cim <message> / cm <message> - variants
# d - the diff of current change
# dr <revset> - the diff of revision <revset>
# e <revset> - edit any <revset> after commit
# (after edit, just go anywhere else (with e or n), the changes will be commited; or an explicit `jj commit` will do)
#
# ## Typical workflow with GitHub
#
# (inspired by https://jj-vcs.github.io/jj/latest/github/ )
#
# ### named branch
#
# bs <bookmark> -r <revset> - move bookmark <bookmark> to <revset>
#
# prb <bookmark> - create a PR from <bookmark> to the default branch
#
# This actually combines:
#
# psb <bookmark> - push bookmark to remote branch named <bookmark>
# gh pr create --head <bookmark> - create a PR from <bookmark> to the default branch
#
# git fetch - will update local bookmark from remote branch
#
# ### unamed branch
#
# prw - open (committed) working copy as a PR
#
# This actually combines:
#
# pscw - push changes of working copy to remote branch named jj/<changeid>
# prow - open working copy as a PR
#
# ### History cleanup
#
# undo - undo last jj operation when messed up
# rebase -s <src> -d <dst> - rebase <src> onto <dst>
# sqar <revset> - squash <revset> into its parent
# squash --from <src> --to <dst> - squash <src> into <dst>
#
# ### Safeguard
#
# log -r <revset> - check your understanding of <revset> syntax: https://github.com/mmlb/jj-vcs-jj/blob/main/docs/revsets.md
# file list <fileset> - check your understanding of <fileset> syntax: https://github.com/mmlb/jj-vcs-jj/blob/main/docs/filesets.md
#
prep-jj:
    which jj || brew install jj
    mkdir -p ~/.config/jj
    cp -f dotfiles/.config/jj/config.toml ~/.config/jj/config.toml
    jj config set --user user.name "$(git config --get user.name)"
    jj config set --user user.email "$(git config --get user.email)"
    jj config list --no-pager

prep-jjui:
    # which lazyjj || brew install lazyjj
    which jjui || brew install jjui
    mkdir -p ~/.config/jjui
    cp -f dotfiles/.config/jjui/config.toml ~/.config/jjui/config.toml

init-jj PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    jj status || jj git init --colocate

push PROJ="forest" BRANCH="main":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    just chk
    jj bs {{BRANCH}} -r @-
    jj psb {{BRANCH}}
    jj psb {{BRANCH}} --remote tangled
    jj psb {{BRANCH}} --remote berg
    which rad && git push rad main

jjpr PROJ="ocaml-forester":
    cd ~/projects/{{PROJ}} && jj prw

jjprp PROJ="ocaml-forester":
    cd ~/projects/{{PROJ}} && jj pscw

# Prep mail patch
#
# pyonji init is handy for setting up git send-mail
# but it doesn't work well with jj when resubmitting patch
# - it won't be able to forget my test with sending to my own email prior to sending to the actual mailing list
# - it won't be able to send 2 different patches against main, because they are not on any branch in jj
# so I use the old-fashion
# `git send-email --to="~jonsterling/forester-devel@lists.sr.ht" HEAD^`
#
prep-mailp:
    which pyonji || go install 'git.sr.ht/~emersion/pyonji@latest'

mailp PROJ="ocaml-forester":
    cd ~/projects/{{PROJ}} && pyonji

# should test with my email first
# then
# ~jonsterling/forester-devel@lists.sr.ht
mailpp MAIL PROJ="ocaml-forester":
    cd ~/projects/{{PROJ}} && git send-email --to="{{MAIL}}" HEAD^

# the idea is to use this for id of garden notes
# i.e. the id of a random note is the short jj change id when it was first added
#
@jjid REVSET="@":
    jj log -r {{REVSET}} -T 'change_id.short()' --no-graph

# Follow https://radicle.xyz/guides/user for rad and git
# then follow https://radicle.xyz/2025/08/14/jujutsu-with-radicle for jj
# forest is published to https://app.radicle.xyz/nodes/iris.radicle.xyz/rad%3Az3mXN7u6s38jqe5F1W3f5xwEzQsT3
# and I am https://app.radicle.xyz/nodes/iris.radicle.xyz/users/did:key:z6Mkoi6L46Tr54sMQmctod6Q43VjYyLwBh8VwJvftMZwdiHt
#
# see https://radicle.zulipchat.com/#narrow/channel/369873-support/topic/How.20to.20push.20on.20a.20new.20device
# for how to push on new device
#
# with a new node identity:
#
# ```
# git remote add rad rad://REPO_RAD_ID/DEVICE_B_NODE_ID
# rad seed rad:REPO_RAD_ID
# git push rad main
# rad sync
# ```
#
# recover the delegate node identity: backup and recover keys to ~/.radicle/keys
#
prep-rad:
    #!/usr/bin/env bash
    set -e
    export PATH="$HOME/.radicle/bin:$PATH"
    # which rad || (curl -sSf https://radicle.xyz/install | sh -s -- --no-modify-path) # -s -- --prefix=~/.local)
    cargo install --force --locked --root ~/.radicle \
        --git https://seed.radicle.xyz/z3gqcJUoA1n9HaHKufZs5FCSGazv5.git \
        radicle-cli radicle-node radicle-remote-helper
    cargo install --force --locked --git https://seed.radicle.xyz/z39mP9rQAaGmERfUMPULfPUi473tY.git
    rad auth
    rad self
    rad node start
    rad node status

# prep-rad-gui:
#     curl --output ~/Downloads/radicle-desktop-aarch64-latest.dmg https://files.radicle.xyz/releases/radicle-desktop/latest/radicle-desktop-aarch64.dmg && open ~/Downloads/radicle-desktop-aarch64-latest.dmg

prep-rad-gui:
    #!/usr/bin/env bash
    set -e
    cd ~/projects
    git clone https://seed.radicle.dev/z4D5UCArafTzTQpDZNQRuqswh3ury.git radicle-desktop
    cd radicle-desktop
    npm install
    npm run tauri build

prep-rad-tui:
    cargo install --force --locked --git https://seed.radicle.xyz/z39mP9rQAaGmERfUMPULfPUi473tY.git

[macos]
prep-rad-httpd:
    #!/usr/bin/env bash
    # which radicle-httpd || (cd /tmp
    # TARGET=0.20.0-aarch64-apple-darwin
    # rip radicle-httpd-$TARGET.tar.xz
    # curl -O -L https://files.radicle.xyz/releases/radicle-httpd/latest/radicle-httpd-$TARGET.tar.xz
    # tar -xvJf radicle-httpd-$TARGET.tar.xz --strip-components=1 -C ~/.radicle/)
    cargo install --force --locked --root ~/.radicle \
        --git https://seed.radicle.xyz/z4V1sjrXqjvFdnCUbxPFqd5p4DtH5.git \
        radicle-httpd



# push with git push rad main
#
init-rad REPO="forest" DEFAULT_BRANCH="main":
    #!/usr/bin/env bash
    cd ~/projects/{{REPO}}
    git config --local --add init.defaultBranch main
    rad init
    rad .

rad-seed:
    # forest
    rad seed rad:z3mXN7u6s38jqe5F1W3f5xwEzQsT3
    # web
    rad seed rad:z4V1sjrXqjvFdnCUbxPFqd5p4DtH5
    # heartwood
    rad seed rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5
    echo "Add the following to web.pinned.repositories of $HOME/.radicle/config.json except the trailing comma, then run: rad node stop; rad node start"
    rad seed | grep -F 'rad:'|awk '{ print "\"" $2 "\"," }'

rad-web:
    #!/usr/bin/env bash
    just prep-rad-httpd
    mkdir -p ~/projects
    cd ~/projects
    DIR=radicle-explorer
    if [ ! -d $DIR/.git ]; then
        git clone https://seed.radicle.xyz/z4V1sjrXqjvFdnCUbxPFqd5p4DtH5.git $DIR
    else
        (cd $DIR && git pull) || true
    fi
    cd $DIR
    npm install
    export DEFAULT_HTTPD_PORT=8776
    npm start &
    pid_ui=$!
    radicle-httpd --listen 0.0.0.0:$DEFAULT_HTTPD_PORT &
    pid_api=$!
    (sleep 1 && echo -e "Visit http://localhost:3000/nodes/iris.radicle.xyz/users/did:key:z6Mkoi6L46Tr54sMQmctod6Q43VjYyLwBh8VwJvftMZwdiHt\n or http://localhost:3000/nodes/127.0.0.1:$DEFAULT_HTTPD_PORT/users/did:key:z6Mkoi6L46Tr54sMQmctod6Q43VjYyLwBh8VwJvftMZwdiHt")
    trap 'kill $pid_ui $pid_api' INT
    wait


## Code forge

prep-fj:
    docker pull data.forgejo.org/forgejo/forgejo:10

FJ_DIR :=  join(home_directory(), ".forgejo")

fj:
    #!/usr/bin/env bash
    mkdir -p {{FJ_DIR}}/ssh
    docker run --rm -it -e USER_UID=$(id -u) -e USER_GID=$(id -g) --env-file .env -p 23000:3000 -p 2222:22 -v {{FJ_DIR}}:/data -v /etc/timezone:/etc/timezone:ro -v /etc/localtime:/etc/localtime:ro data.forgejo.org/forgejo/forgejo:10

prep-filter-repo:
    which git-filter-repo || brew install git-filter-repo

# Transfer directory with full history from repo A to repo B with optional rename
# REPO_A: path to source repo
# DIR_A: directory in repo A to transfer
# REPO_B: path to destination repo
# DIR_B: target directory in repo B (use "." for root)
# DRY_RUN: set to empty string to execute (default: "--dry-run")
#
# Example: just migrate-dir ~/repos/source mydir ~/repos/dest newdir
# Example: just migrate-dir ~/repos/source mydir ~/repos/dest . ""
migrate-dir REPO_A DIR_A REPO_B DIR_B DRY_RUN="--dry-run":
    #!/usr/bin/env bash
    set -e
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    echo "=== Cloning repo A to temp location ==="
    git clone {{REPO_A}} $TEMP_DIR/filtered

    cd $TEMP_DIR/filtered
    echo "=== Filtering to keep only {{DIR_A}} ==="
    git-filter-repo --path {{DIR_A}} --force

    if [ "{{DIR_B}}" != "{{DIR_A}}" ] && [ "{{DIR_B}}" != "." ]; then
        echo "=== Renaming {{DIR_A}} to {{DIR_B}} ==="
        git-filter-repo --path-rename {{DIR_A}}:{{DIR_B}} --force
    elif [ "{{DIR_B}}" = "." ]; then
        echo "=== Moving {{DIR_A}} to root ==="
        git-filter-repo --path-rename {{DIR_A}}: --force
    fi

    if [ "{{DRY_RUN}}" = "--dry-run" ]; then
        echo ""
        echo "=== DRY RUN: Would merge into {{REPO_B}} ==="
        echo "Filtered commits:"
        git log --oneline --graph --all
        echo ""
        echo "To execute, run: just migrate-dir {{REPO_A}} {{DIR_A}} {{REPO_B}} {{DIR_B}} \"\""
    else
        echo "=== Merging into repo B ==="
        cd {{REPO_B}}
        git remote add temp-filtered $TEMP_DIR/filtered
        git fetch temp-filtered
        git merge --allow-unrelated-histories temp-filtered/main -m "Migrate {{DIR_A}} from repo A"
        git remote remove temp-filtered
        echo "=== Migration complete ==="

        echo ""
        echo "=== Cleanup repo A? ==="
        echo "This will:"
        echo "  1. Remove {{DIR_A}} from working tree"
        echo "  2. Commit the removal"
        echo "  3. Purge {{DIR_A}} history from repo A (shrink size)"
        echo ""
        read -p "Proceed with cleanup? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd {{REPO_A}}
            ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
            git rm -r {{DIR_A}}
            git commit -m "Remove {{DIR_A}} directory (migrated to separate repo)"
            git-filter-repo --path {{DIR_A}} --invert-paths --force
            if [ -n "$ORIGIN_URL" ]; then
                git remote add origin "$ORIGIN_URL"
            fi
            echo ""
            echo "✓ Cleanup complete!"
            echo "⚠️  To push changes, run: cd {{REPO_A}} && git push --force"
        else
            echo "Skipped cleanup. To clean up later:"
            echo "  cd {{REPO_A}}"
            echo "  git rm -r {{DIR_A}}"
            echo "  git commit -m 'Remove {{DIR_A}} directory (migrated to separate repo)'"
            echo "  git-filter-repo --path {{DIR_A}} --invert-paths --force"
            echo "  git push --force"
        fi
    fi

# Mirror directories from source repo to dest repo, preserving git history.
# Reads a file with one directory per line. Supports incremental runs.
# Source repo is read-only. History conflict detection: if both repos have
# commits on the same file, source commits must all precede dest commits.
#
# REPO_SRC: path to source repo (read-only)
# REPO_DST: path to destination repo
# DIRS_FILE: path to a text file with one directory per line to mirror
# DRY_RUN: set to empty string to execute (default: "--dry-run")
#
# Example: just mirror-dirs ~/repos/mine ~/repos/cog-land dirs.txt
# Example: just mirror-dirs ~/repos/mine ~/repos/cog-land dirs.txt ""
mirror-dirs REPO_SRC REPO_DST DIRS_FILE DRY_RUN="--dry-run":
    #!/usr/bin/env bash
    set -e

    REPO_SRC="$(cd "{{REPO_SRC}}" && pwd)"
    REPO_DST="$(cd "{{REPO_DST}}" && pwd)"
    DIRS_FILE="{{DIRS_FILE}}"

    if [ ! -f "$DIRS_FILE" ]; then
        echo "ERROR: dirs file not found: $DIRS_FILE"
        exit 1
    fi

    # Read directory list (skip empty lines and comments)
    DIRS=()
    while IFS= read -r line; do
        line="${line%%#*}"       # strip comments
        line="$(echo "$line" | xargs)" # trim whitespace
        [ -z "$line" ] && continue
        DIRS+=("$line")
    done < "$DIRS_FILE"

    if [ ${#DIRS[@]} -eq 0 ]; then
        echo "ERROR: no directories found in $DIRS_FILE"
        exit 1
    fi

    echo "=== mirror-dirs ==="
    echo "Source:  $REPO_SRC"
    echo "Dest:    $REPO_DST"
    echo "Dirs:    ${DIRS[*]}"
    echo "Mode:    $( [ '{{DRY_RUN}}' = '--dry-run' ] && echo 'DRY RUN' || echo 'EXECUTE' )"
    echo ""

    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    ERRORS=0
    MIRRORED=0
    SKIPPED=0

    for DIR in "${DIRS[@]}"; do
        echo "--- Mirroring: $DIR ---"
        cd "$REPO_SRC"  # Reset working directory each iteration

        # Check directory exists in source
        if ! (cd "$REPO_SRC" && git log --oneline -1 -- "$DIR" >/dev/null 2>&1); then
            echo "  SKIP: $DIR has no history in source repo"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi

        # Clone source and filter to just this directory
        DIR_SLUG=$(echo "$DIR" | tr '/' '-')
        FILTERED="$TEMP_DIR/filtered-$DIR_SLUG"
        rm -rf "$FILTERED"
        if ! git clone --no-tags "$REPO_SRC" "$FILTERED" 2>/dev/null; then
            echo "  ERROR: Failed to clone source repo"
            ERRORS=$((ERRORS + 1))
            continue
        fi

        cd "$FILTERED"
        git-filter-repo --path "$DIR" --force --quiet

        FILTERED_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo 0)
        if [ "$FILTERED_COUNT" = "0" ]; then
            echo "  SKIP: $DIR has no commits after filtering"
            SKIPPED=$((SKIPPED + 1))
            rm -rf "$FILTERED"
            continue
        fi

        echo "  Source commits: $FILTERED_COUNT"

        # Check for existing history in dest and handle incremental
        cd "$REPO_DST"
        DEST_HAS_DIR="no"
        if git log --oneline -1 -- "$DIR" >/dev/null 2>&1; then
            DEST_HAS_DIR="yes"
        fi

        if [ "$DEST_HAS_DIR" = "yes" ]; then
            echo "  Dest already has history for $DIR — checking for incremental..."

            # Get source commit hashes (after filtering)
            cd "$FILTERED"
            SRC_HASHES=$(git log --format='%H' | sort)

            # Get dest commit hashes that touch this directory
            # (excluding merge commits which are the mirror merge commits)
            cd "$REPO_DST"
            DST_HASHES=$(git log --no-merges --format='%H' -- "$DIR" | sort)

            # Find source commits already in dest (by comparing author date + message)
            # Since filter-repo rewrites hashes, we compare by author date + subject
            cd "$FILTERED"
            SRC_SIGS=$(git log --format='%aI|%s' | sort)
            cd "$REPO_DST"
            DST_SIGS=$(git log --no-merges --format='%aI|%s' -- "$DIR" | sort)

            # Check how many source signatures are already in dest
            ALREADY_IN_DEST=0
            NEW_IN_SRC=0
            while IFS= read -r sig; do
                [ -z "$sig" ] && continue
                if echo "$DST_SIGS" | grep -qF "$sig"; then
                    ALREADY_IN_DEST=$((ALREADY_IN_DEST + 1))
                else
                    NEW_IN_SRC=$((NEW_IN_SRC + 1))
                fi
            done <<< "$SRC_SIGS"

            if [ "$NEW_IN_SRC" -eq 0 ]; then
                echo "  SKIP: All $ALREADY_IN_DEST source commits already in dest (up to date)"
                SKIPPED=$((SKIPPED + 1))
                rm -rf "$FILTERED"
                continue
            fi

            echo "  Found $NEW_IN_SRC new commits ($ALREADY_IN_DEST already mirrored)"

            # For new commits, check they don't conflict with dest-only commits
            # Get the latest source commit timestamp and earliest dest-only commit
            cd "$FILTERED"
            SRC_LATEST_TS=$(git log -1 --format='%aI')

            # Find dest commits that are NOT from source (dest-only)
            cd "$REPO_DST"
            DEST_ONLY_EARLIEST=""
            while IFS= read -r dsig; do
                [ -z "$dsig" ] && continue
                if ! echo "$SRC_SIGS" | grep -qF "$dsig"; then
                    ts="${dsig%%|*}"
                    if [ -z "$DEST_ONLY_EARLIEST" ] || [[ "$ts" < "$DEST_ONLY_EARLIEST" ]]; then
                        DEST_ONLY_EARLIEST="$ts"
                    fi
                fi
            done <<< "$DST_SIGS"

            if [ -n "$DEST_ONLY_EARLIEST" ]; then
                # Use python for reliable ISO 8601 timestamp comparison
                SRC_TS=$(python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('$SRC_LATEST_TS').timestamp()))")
                DST_TS=$(python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('$DEST_ONLY_EARLIEST').timestamp()))")

                if [ "$SRC_TS" -ge "$DST_TS" ]; then
                    echo "  CONFLICT: source latest ($SRC_LATEST_TS) overlaps with dest-only commit ($DEST_ONLY_EARLIEST)"
                    echo "  ERROR: History conflict for $DIR — skipping (dest unchanged)"
                    ERRORS=$((ERRORS + 1))
                    rm -rf "$FILTERED"
                    continue
                fi
                echo "  No conflicts — new source commits are before dest-only commits"
            else
                echo "  No dest-only commits — safe to merge"
            fi
        fi

        if [ "{{DRY_RUN}}" = "--dry-run" ]; then
            echo "  DRY RUN: Would merge $FILTERED_COUNT commits for $DIR"
            cd "$FILTERED"
            git log --oneline | head -5
            [ "$FILTERED_COUNT" -gt 5 ] && echo "  ... and $((FILTERED_COUNT - 5)) more"
            MIRRORED=$((MIRRORED + 1))
        else
            echo "  Merging into dest..."
            cd "$REPO_DST"
            REMOTE_NAME="mirror-$(echo "$DIR" | tr '/' '-')-$$"
            git remote add "$REMOTE_NAME" "$FILTERED"
            git fetch "$REMOTE_NAME" 2>/dev/null

            # Determine the branch name in the filtered repo
            FILTERED_BRANCH=$(cd "$FILTERED" && git branch --show-current 2>/dev/null || echo "main")
            # Use -X ours to keep dest content on conflicts (source history is older)
            git merge --allow-unrelated-histories "$REMOTE_NAME/$FILTERED_BRANCH" \
                -m "Mirror $DIR from source repo" --no-edit -X ours

            git remote remove "$REMOTE_NAME"
            MIRRORED=$((MIRRORED + 1))
            echo "  OK: $DIR mirrored ($FILTERED_COUNT commits)"
        fi

        rm -rf "$FILTERED"
    done

    echo ""
    echo "=== Summary ==="
    echo "Mirrored: $MIRRORED"
    echo "Skipped:  $SKIPPED"
    echo "Errors:   $ERRORS"
    if [ "{{DRY_RUN}}" = "--dry-run" ]; then
        echo ""
        echo "This was a dry run. To execute:"
        echo "  just mirror-dirs {{REPO_SRC}} {{REPO_DST}} {{DIRS_FILE}} \"\""
    fi
    [ "$ERRORS" -gt 0 ] && exit 1 || exit 0

# then run: git clone http://localhost:63000/username/repo.git:/dir.git
# but no arm64 version yet
# josh-proxy:
#     #!/usr/bin/env bash
#     docker run \
#         -p 63000:8000 \
#         -e JOSH_REMOTE=https://github.com \
#         dockerproxy.net/joshproject/josh-proxy:latestS
#
josh-proxy:
    #!/usr/bin/env bash
    mkdir -p ~/.josh
    just clone josh-project josh
    cd ~/projects/josh/josh-proxy
    cargo run -- --port 63000 --remote https://github.com --local ~/.josh

josh WHERE USER REPO DIR:
    #!/usr/bin/env bash
    cd ~/projects/
    git clone http://localhost:63000/{{USER}}/{{REPO}}.git:/{{DIR}}.git {{WHERE}}
    cd {{WHERE}}
    git remote rename origin origin_josh || true
    echo 'cd ~/projects/{{WHERE}} && git remote add origin https://github.com/{{USER}}/NEW_REPO_NAME.git'
    echo 'gh auth setup-git'
    echo 'git push -u origin BRANCH'

