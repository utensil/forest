# Terminal Setup Tasks

## Terminal basic CLIs

# TODO: break down to essentials and extra pack

prep-term:
    # Basic CLI
    which wget || brew install wget
    which nproc || brew install coreutils
    # Shell
    which zsh || brew install zsh
    which starship || brew install starship
    which zoxide || brew install zoxide
    # Git
    which lazygit || brew install lazygit
    which gh || brew install gh
    @echo "Remember to run: gh auth login"
    @echo "And possibly: gh auth refresh -s read:project"
    # File
    which duf || brew install duf
    which dua || brew install dua-cli
    which bat || brew install bat
    which eza || brew install eza
    which rip || brew install rm-improved
    which yazi || brew install yazi
    which 7zz || brew install sevenzip
    # Search & replace
    which fzf || brew install fzf
    which rg || brew install ripgrep
    which sd || brew install sd
    # which serpl || brew install serpl
    which scooter || brew install scooter
    # Code
    which cmake || brew install cmake
    which pkg-config || brew install pkg-config
    which tokei || brew install tokei
    # Format
    which jq || brew install jq
    which hexyl || brew install hexyl

prep-media:
    which magick ||brew install imagemagick
    which ffmpeg || brew install ffmpeg
    which mpv || brew install mpv

# they were tried but seldom used
#
prep-term-seldom:
    which yq || brew install yq
    which nnn || brew install nnn
    which progress || brew install progress
    which sq || brew install sq
    which fex || (curl -sSL https://raw.githubusercontent.com/18alantom/fex/master/install.sh | bash)

prep-mon:
    #!/usr/bin/env zsh
    # which glances || brew install glances
    which btop || brew install btop
    which btm || brew install bottom
    # stats is part of the sudoless monit tool community
    # [ ! -f /Applications/Stats.app ] && brew install stats
    if [ "$(uname)" = "Darwin" ]; then
        which mactop || brew install mactop
        # if the arch is aarch64 or arm64
        if [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then
            which macmon || brew install vladkens/tap/macmon
            # which neoasitop || (brew tap op06072/neoasitop && brew install neoasitop)
        else
            echo "No GPU monit tools found yet"
        fi
    fi

awake:
    # caffeinate -d -s
    caffeinate -s

# ctrl+r - atuin history TUI
# In TUI:
#   - ctrl+r - cycle through filter mode: global, host, session, directory
#   - ctrl+s - cycle through search mode: fuzzy, prefix, fulltext
#   - anything - search history
#   - enter - execute
#   - tab   - edit
#   - ctrl+o - inspect (stats)
#
# https://docs.atuin.sh/guide/installation/
# https://docs.atuin.sh/configuration/key-binding/#atuin-ui-shortcuts
# Prepare atuin for history management/syncing
prep-his:
    which atuin || brew install atuin
    # atuin register -u <YOUR_USERNAME> -e <YOUR EMAIL>
    # atuin key
    # atuin import auto
    # atuin login -u <YOUR_USERNAME>
    # echo 'eval "$(atuin init zsh)"'
    # atuin sync

## Ghostty

# based on https://gist.github.com/davidteren/898f2dcccd42d9f8680ec69a3a5d350e
#
find-font FONT="maple":
    #!/usr/bin/env zsh
    brew search '/font-.*-(nerd-font|nf)/' | awk '{ print $1 }' | grep -i {{FONT}}

[macos]
list-font FONT="fonts":
    fc-list|grep -i {{FONT}}

# https://github.com/subframe7536/Maple-font
#
prep-font:
    brew install --cask font-fira-code-nerd-font
    brew install --cask font-fira-mono-nerd-font
    brew install --cask font-maple-mono-nf-cn

prep-gt:
    which ghostty || brew install --cask ghostty
    just sync-gt
    just prep-gtsh

prep-gtsh:
    #!/usr/bin/env bash
    just clone m-ahdal ghostty-shaders
    just clone utensil shader-playground

# Cmd+Ctrl+F to toggle fullscreen, or just Cmd + Enter
# Cmd + D to split right
# Cmd + Shift + D to split bottom
# Cmd + Option + arrows to move between splits, or just Cmd + [ or ]
# Cmd + Shift + Enter to zoom in/out the current split
# Cmd + w to close the current split
# Drag the separator to resize splits (need to observe a band that's more transparent, then drag it blindly without waiting for the cursor change)
# Cmd + Shift + , to reload the config, or just Cmd + R
# Cmd + up/down to jump to prev/next command issued in the terminal (a.k.a jump to prompt)
# Cmd + Shift + J to dump scrollback to a file, allow searching etc. via a pager
# more default key bindings: http://w.yet.org/posts/2024-12-30-ghostty/
#
keys-gt:
    ghostty +list-keybinds --default

sync-gt:
    mkdir -p ~/.config/
    rip ~/.config/ghostty || true
    ln -s {{justfile_directory()}}/dotfiles/.config/ghostty ~/.config/ghostty

reset-gt:
    rip ~/.config/ghostty

# https://github.com/ghostty-org/ghostty/discussions/7194
#
log-gt:
    sudo log stream --level debug --predicate 'subsystem=="com.mitchellh.ghostty"'

## Shell setup

prep-zsh:
    brew install zsh-autosuggestions zsh-syntax-highlighting
    # zsh-vi-mode

prof-zsh:
    time zsh -i -c exit

# Start a zsh that inherits .env
zsh PROJ="forest":
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}}
    zsh

# a ssh that inherits .env etc.
#
ssh *PARAMS:
    ssh {{PARAMS}}

prep-rc:
    # show diff before copying (dotfiles as new, ~ as old)
    delta --color-only ~/.envrc dotfiles/.envrc || true
    delta --color-only ~/.bashrc dotfiles/.bashrc || true
    delta --color-only ~/.zshrc dotfiles/.zshrc || true
    # copy with confirmation
    cp -i dotfiles/.envrc ~/.envrc
    cp -i dotfiles/.bashrc ~/.bashrc
    cp -i dotfiles/.zshrc ~/.zshrc

prep-rcy:
    yes|just prep-rc

add-zrc LINE:
    grep -F '{{LINE}}' ~/.zshrc || echo '{{LINE}}' >> ~/.zshrc

add-brc LINE:
    grep -F '{{LINE}}' ~/.bashrc || echo '{{LINE}}' >> ~/.bashrc


chsh:
    # chsh -s `chsh -l|grep zsh|head -1` `whoami`
    # chsh -s `which zsh` `whoami`

## Git

prep-git:
    #!/usr/bin/env zsh
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
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}} && lazygit {{PARAMS}}

# [NOTE] If modified, test with prep-gtsh
#
clone USER REPO:
    #!/usr/bin/env zsh
    mkdir -p ~/projects
    FULL_REPO={{USER}}/{{REPO}}
    DIR=~/projects/{{REPO}}
    if [ ! -d $DIR/.git ]; then
        git clone https://github.com/$FULL_REPO $DIR
    else
        (cd $DIR && git pull) || true
    fi

clone-conf CONF USER REPO:
    #!/usr/bin/env zsh
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
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}} && gh workflow view {{PARAMS}}

prep-date:
    which git-backdate || (curl https://raw.githubusercontent.com/rixx/git-backdate/main/git-backdate > /usr/local/bin/git-backdate && chmod +x /usr/local/bin/git-backdate)
    which gdate || brew install coreutils

date: prep-date
    #!/usr/bin/env zsh
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
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}}
    jj status || jj git init --colocate

push PROJ="forest" BRANCH="main":
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}}
    jj bs {{BRANCH}} -r @-
    jj psb {{BRANCH}}
    jj psb {{BRANCH}} --remote tangled
    jj psb {{BRANCH}} --remote berg

## Languages

# https://blog.vbang.dk/2025/06/29/tools-i-love-mise/
#
prep-mise:
    #!/usr/bin/env zsh
    which mise || brew install mise
    echo 'Ensure run the following in ~/.bashrc or ~/.zshrc:'
    echo 'eval "$(mise activate $(basename "$0"))"'
    cat << 'EOF'
    e.g. echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
    EOF
    # mise supports popular programming languages (including zig) with core plugins
    # https://github.com/jdx/mise/tree/main/src/plugins/core

prep-rust:
    #!/usr/bin/env bash
    set -e
    which cargo || (
        (curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly) &&
        (just add-zrc '. $HOME/.cargo/env' && echo 'Run: . $HOME/.cargo/env')
    )
    . $HOME/.cargo/env
    which cargo-binstall || cargo install cargo-binstall

prep-node:
    which node || brew install node

# https://github.com/astral-sh/uv

[unix]
prep-uv:
    curl -LsSf https://astral.sh/uv/install.sh | sh


[windows]
prep-uv:
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

prep-py:
    uv python install 3.11
    uv venv --python 3.11 --seed

prep-go:
    which go || brew install go

# https://thinkingelixir.com/install-elixir-using-asdf/
# prep-asdf:
#     which asdf || brew install asdf
#     just prep-rc

# prep-ex: prep-asdf
#     asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git
#     asdf install elixir v1.18
#     asdf global elixir ref:v1.18

prep-ex:
    which iex || brew install elixir
    which elixir
    which elixirc
    which mix

## Tmux and friends

# Try Zellij
#
# default key bindings (I don't like them)
# Ctrl+P N to create a new pane
# Ctrl+P then direction keys to move between panes
# Ctrl+P Z to hide frames
# Ctrl+N then direction keys to resize the corrent pane towards the direction
# Ctrl+O W to manage sessions
# try-zj:
#     #!/usr/bin/env zsh
#     bash <(curl -L https://zellij.dev/launch)

# Install Zellij, set its visual to minimal, keybindings to tmux
prep-zj:
    #!/usr/bin/env zsh
    which zellij || brew install zellij
    # just clone-conf zellij t3hmrman tmux-zellij-shim-config
    rip ~/.config/zellij || true
    just link-conf zellij
    # ln -s {{justfile_directory()}}/dotfiles/.config/zellij ~/.config/zellij
    # just cp dotfiles/.config/zellij ~/.config/zellij

# attach - a
# list - ls
# kill all session - ka
# delete all session - da
#
# Ctrl+b as trigger, follow by
# ? for a list of key bindings
# session manager - s
#   next tab - tab
#   rename - ctrl+r
#   delete - del
# d - detach
# | - vsplit
# - - hsplit
# arrows or hjkl - move between splits
# t - new tab
# p n - prev/next tab
# [ - into scroll/copy mode
#
zj *PARAMS:
    #!/usr/bin/env zsh
    zellij {{PARAMS}}

# Will attatch to a session if running (will attach it as a new client, all clients can see and operate on the same session)
# or killed (will resurrect it, each pane will remember the last running command and wait for confirm to run)
#
at NAME="mon":
    #!/usr/bin/env zsh
    LAYOUT=$(echo {{NAME}}|sed 's/-.*//g')
    (zellij ls|grep {{NAME}}) && just zj a {{NAME}} || just zj -s {{NAME}} -n $LAYOUT || just zj -s {{NAME}}

# destructive, for debugging layout only, comment out after debug
#
new-at NAME="mon":
    #!/usr/bin/env zsh
    LAYOUT=$(echo {{NAME}}|sed 's/-.*//g')
    just zj d {{NAME}} --force ; just zj -s {{NAME}} -n $LAYOUT

kill NAME:
    #!/usr/bin/env zsh
    ps aux|grep {{NAME}}|grep -v grep|grep -v 'kill {{NAME}}'
    read -q "?Confirm killing these processes (y/n)? " && (ps aux|grep {{NAME}}|grep -v grep|grep -v 'kill {{NAME}}'|awk '{print $2}'|xargs kill -9) || echo "\nKill aborted"

# runf SESSION="mon" CMD="zsh":
#     zellij run -f -n {{SESSION}} -- {{CMD}}

prep-tmux:
    which tmux || brew install tmux
    ln -sf {{justfile_directory()}}/dotfiles/.config/tmux ~/.config/tmux
    ls -lhta ~/.config/tmux
    tmux start-server

# adapted from https://maxscheijen.github.io/posts/managing-tmux-sessions-with-fzf/
#
ftm:
    #!/usr/bin/env zsh
    session=$(tmux ls | awk -F: '
        /attached/ {print $1 "\033[32m *\033[0m"}
        !/attached/ {print $1}
    ' | fzf --ansi)
    session=$(echo "$session" | sed 's/ (attached)$//')
    if [ -n "$session" ]; then
        tmux switch-client -t "$session" || tmux attach-session -t "$session"
    else
        echo "No session selected."
    fi

# prefix key: ctrl+b
#
# r - reload config
#
# c - new window
# <number> - switch to window <number>
#
# $ - rename current session
# . - rename current window
# , - rename current tab
#
# " - split -
# % - split |
# <direction> - move between panes
# z - zoom the current pane
#
# d - detach
# x - kill the current pane
# & - kill the current window
#
tm-at NAME:
    #!/usr/bin/env zsh
    tmux attach -t {{NAME}} || tmux new-session -s {{NAME}}

tm-mon:
    #!/usr/bin/env zsh
    tmux attach -t mon || tmux new-session -s mon -d 'btop || zsh' \; \
      split-window -h 'macmon || zsh' \; \
      split-window -v -t 1 'sudo mactop || zsh' \; \
      select-pane -t 0 \; \
      attach

tm-dev:
    #!/usr/bin/env zsh
    tmux attach -t dev || tmux new-session -s dev -d 'just dev || zsh' \; \
      split-window -h -p 50 'just cpa || zsh' \; \
      select-pane -t 0 \; \
      split-window -v -p 25 -t 0 'just awake || zsh' \; \
      attach

# https://github.com/kovidgoyal/kitty/issues/391#issuecomment-778703119
# persistent session: abduco
# multiplexer: dvtm
# Creating a session
# just tach -c name zsh
# Ctrl+\ to detach, or use -e ^q to use Ctrl+q
# Attaching to a session
# BUT can't detach from within Helix
# just tach -a name
#
prep-abduco:
    which abduco || brew install abduco

abduco *PARAMS:
    abduco {{PARAMS}}

# linux only for now
# see https://github.com/shell-pool/shpool/issues/183
#
prep-pool:
    cargo install shpool

prep-ds:
    cargo install diss

# works for mon running btop
# not really working for nvim etc.
# diss-at SESSION="main":
#     diss -e g -a {{SESSION}} zsh

## Container and friends

# prep-pod:
#    # brew uninstall orbstack
#    which docker || brew install docker
#    brew install podman-desktop
#    docker context use default

prep-pod:
    which docker || (brew install docker; brew link docker)
    which docker-compose || brew install docker-compose
    which colima || brew install colima
    which kubectl || brew install kubectl
    docker context use default

# https://github.com/abiosoft/colima?tab=readme-ov-file#customizing-the-vm
# to run x86_64 containers:
# 1. run colima delete which will delete all existing container!
# 2. colima start --vm-type=vz --vz-rosetta --network-address
# 3. docker pull --platform linux/amd64 ubuntu:jammy # with docker login first
# see also:
# `just prep-lima` which prepares a Lima VM with Ubuntu 25.04 x86_64 that is ready to run x86_64 static binaries and containers
# https://github.com/lima-vm/lima/discussions/1573 for realizing the VM is still arm64
# https://github.com/lima-vm/lima/discussions/1043#discussioncomment-3560889 for realizing only statically linked binaries work in VM, dynamically linked ones fail due to missing shared libraries, so they should be run in containers, so just use colima options for this!
#
# to access lan, `--network-address` is needed
# see https://github.com/abiosoft/colima/blob/main/docs/FAQ.md#the-virtual-machines-ip-is-not-reachable
#
pod CMD="start --vm-type=vz --vz-rosetta --network-address":
    colima {{CMD}}

# tested in lima
# distrobox create --name test --init --image quay.io/toolbx-images/alpine-toolbox:latest
# distrobox enter test
# https://github.com/89luca89/distrobox/blob/main/docs/compatibility.md#containers-distros
[linux]
prep-dist:
    which distrobox || sudo apt install -y distrobox
    which docker || sudo apt install podman-docker

k8s:
    colima start --kubernetes

docker-save IMAGE FILE:
    docker save {{IMAGE}} -o {{FILE}}

prep-lima:
    which lima || brew install lima
    # limactl stop default
    # limactl delete default
    limactl create --name=default dotfiles/lima/ubuntu-25.04-x86_64.yaml
    # limactl start default
    # lima

prep-tilt:
    which tilt || brew install tilt-dev/tap/tilt

# tilt up is usually all you need
#
tilt *PARAMS:
    tilt {{PARAMS}}

# https://github.com/louislam/dockge
# https://github.com/abiosoft/colima/issues/265
#
dockge COMMAND="up" NETWORK_MODE="bridge":
    #!/usr/bin/env zsh
    set -e
    [[ -n "$PODS_HOME" ]] || (echo "PODS_HOME is missing" && exit 1)
    mkdir -p $PODS_HOME/dockge/data
    # keep track of stacks in this repo
    rip $PODS_HOME/dockge/stacks
    ln -s {{justfile_directory()}}/stacks $PODS_HOME/dockge/stacks
    cd stacks/dockge
    # DOCKGE_ENABLE_CONSOLE=true
    # if COMMAND is up
    export NETWORK_MODE={{NETWORK_MODE}}
    if [ "{{COMMAND}}" = "up" ]; then
        docker-compose up -d
        echo Dockge is now running on http://localhost:5001
    elif [ "{{COMMAND}}" = "down" ]; then
        docker-compose down
    fi

# https://github.com/abiosoft/colima/issues/1234
#
prep-ctop:
    which ctop || brew install ctop
    docker context ls

# https://github.com/abiosoft/colima/issues/958#issuecomment-3078908176
# ? - help
# l - log
# e - execute shell
# w - open browser (convention: first port is http)
#
ctop:
    colima status
    DOCKER_HOST=`docker context ls --format json|grep colima|jq -r '.DockerEndpoint'` ctop

prep-lazydocker:
    brew install jesseduffield/lazydocker/lazydocker

# prep-act: prep-term
#     #!/usr/bin/env bash
#     which act || brew install act

# act:
#     ./act.sh

rm-act:
    sudo docker stop act-dev
    sudo docker rm act-dev

mk-act:
    sudo docker run -d --name act-dev -v{{justfile_directory()}}:/root/projects/forest -p 127.0.0.1:1210-1214:1210-1214 ghcr.io/catthehacker/ubuntu:act-latest bash -c 'sleep infinity'

run-act CMD="bash" OPTS="-it":
    sudo docker exec {{OPTS}} -w /root/projects/forest act-dev {{CMD}}

# manually run bootstrap-ubuntu first, or we won't even have just
#
prep-act:
    # for brew and zsh
    just prep-ubuntu
    just prep-act-in-zsh

prep-act-in-zsh:
    #!/usr/bin/env zsh
    source ~/.zshrc
    just prep-term
    just prep-rust
    just prep-lvim-in-zsh
    echo 'To start lvim in server mode, run: just lv-remote'
    echo 'Then from outside the container, run: just lv-local'

## SSH

reset-ssh-keys:
    rip ~/.ssh/id_*; rip ~/.ssh/*_rsa; rip ~/.ssh/*_dsa; rip ~/.ssh/*_ecdsa; rip ~/.ssh/*_ed25519 || true

# still verifying
#
prep-ssh-keys:
    #!/usr/bin/env zsh
    key_path=~/.ssh/id_ed25519
    if [[ ! -f "$key_path" && ! -f "$key_path.pub" ]]; then
        echo "Generating new SSH key pair..."
        ssh-keygen -t ed25519 -a 100 -f "$key_path" -q -N ""
        chmod 600 "$key_path" "$key_path.pub"
        echo "SSH keys generated and permissions set."
    else
        echo "SSH keys already exist at $key_path and $key_path.pub"
        echo "Skipping key generation."
    fi
    cat "$key_path.pub"
    # Read remote user and host
    read "remote_user?Enter remote username: " || return
    read "remote_host?Enter remote hostname or IP: " || return

    # Ask if user wants to proceed with key deployment
    if read -q "?Do you want to deploy the public key now? (y/n) "; then
        echo  # Add a newline after the prompt
        if ssh-copy-id -x -i "$key_path.pub" "$remote_user@$remote_host"; then
            echo "Public key deployed successfully!"
            echo "You can now connect with: ssh $remote_user@$remote_host"
        else
            echo "Failed to deploy key. Please check connection or manually add the key:"
            cat "$key_path.pub"
        fi
    else
        echo "\nPublic key was not deployed. You can manually add this key:"
        cat "$key_path.pub"
    fi

# initial draft, not verified
#
prep-ssh-server:
    #!/usr/bin/env zsh

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi

    # Prompt for the public key
    echo "Please paste your public SSH key (typically from ~/.ssh/id_rsa.pub):"
    read -r public_key

    # Verify the key looks like a valid SSH public key
    if [[ ! "$public_key" =~ ^ssh-(rsa|dss|ed25519|ecdsa) ]]; then
        echo "Error: This doesn't look like a valid SSH public key"
        exit 1
    fi

    # Create .ssh directory if it doesn't exist
    mkdir -p /root/.ssh

    # Add key to authorized_keys
    echo "$public_key" >> /root/.ssh/authorized_keys

    # Set correct permissions
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys

    # Configure SSH server (uncomment to enable)
    # echo "Adding key to SSH server configuration..."
    # echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
    # echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config

    # Restart SSH service (uncomment to enable)
    # echo "Restarting SSH service..."
    # if command -v systemctl >/dev/null; then
    #     systemctl restart sshd
    # else
    #     service ssh restart
    # fi

    echo "Public key added to /root/.ssh/authorized_keys"
    echo "You should now be able to SSH as root using this key"
