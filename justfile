set dotenv-load

export PROJECT_ROOT := justfile_directory()
export HOMEBREW_NO_AUTO_UPDATE := "1"
export XDG_CONFIG_HOME := home_directory() / ".config"

default:
    just --list
    @echo '💡 To initialize just aliases: source alias.sh'

new +PARAMS:
    ./new.sh {{PARAMS}}

build:
    ./build.sh

dev:
    ./dev.sh

lize:
    ./lize.sh

fize:
    ./fize.py

chk:
    ./chk.sh

thm:
    ./thm.sh

prep-bib:
    @echo "pyenv shell 3.11"
    @echo "pip3 install bibtexparser"

bib:
    ./bib.sh

glsl SOURCE:
    mkdir -p output/shader/
    cp -f {{SOURCE}} output/shader/

css SOURCE:
    bunx --bun lightningcss-cli --minify --bundle --targets '>= 0.25%' {{SOURCE}} -o output/{{file_name(SOURCE)}}
    # bunx postcss -o output/{{file_name(SOURCE)}} {{SOURCE}}

js SOURCE:
    bun run bun_build.js {{SOURCE}}

forest:
    opam exec -- forester build # 2>&1 > build/forester.log # --dev

copy SOURCE:
    -rm output/{{file_name(SOURCE)}} > /dev/null 2>&1
    cp -f {{SOURCE}} output/

typ SOURCE:
    mkdir -p output/typst/
    cp -f {{SOURCE}} output/typst/

penrose SOURCE:
    mkdir -p output/penrose/
    cp -f {{SOURCE}} output/penrose/

envs:
    #!/usr/bin/env bash
    echo "PROJECT_ROOT: $PROJECT_ROOT"

install-shellcheck:
    brew install shellcheck

run-shellcheck:
    shellcheck *.sh

prep-term:
    which zsh || brew install zsh
    which nvim || brew install neovim
    which lazygit || brew install lazygit
    which yq || brew install yq
    which gh || brew install gh
    @echo "Remember to run: gh auth login"
    @echo "And possibly: gh auth refresh -s read:project"
    which fzf || brew install fzf
    which yazi || brew install yazi
    which nnn || brew install nnn
    which stylua || brew install stylua
    which sd || brew install sd
    which dua || brew install dua-cli
    which bat || brew install bat
    which eza || brew install eza
    which rg || brew install ripgrep
    which rip || brew install rm-improved
    which luarocks || brew install luarocks
    # luarocks --local --lua-version=5.1 install magick
    which starship || brew install starship
    which zoxide || brew install zoxide
    which magick ||brew install imagemagick
    just add-zrc 'eval "$(zoxide init zsh)"'
    just add-zrc 'eval "$(starship init zsh)"'
    which progress || brew install progress
    which 7zz || brew install sevenzip
    which ffmpeg || brew install ffmpeg
    which tokei || brew install tokei
    # awrit installation usually fails with some warning
    which awrit || brew install chase/tap/awrit || true
    which mpv || brew install mpv
    which cmake || brew install cmake
    which pkg-config || brew install pkg-config
    which nproc || brew install coreutils

prep-gt:
    which ghostty || brew install ghostty
    just prep-gtsh

prep-gtsh:
    #!/usr/bin/env bash
    mkdir -p ~/projects
    if [ ! -d ~/projects/ghostty-shaders ]; then
        git clone https://github.com/m-ahdal/ghostty-shaders ~/projects/ghostty-shaders
    fi

# Cmd+Ctrl+F to toggle fullscreen, or just Cmd + Enter
# Cmd + D to split right
# Cmd + Shift + D to split bottom
# Cmd + Option + arrows to move between splits, or just Cmd + [ or ]
# Cmd + Shift + Enter to zoom in/out the current split
# Cmd + w to close the current split
# Drag the separator to resize splits
# Cmd + Shift + , to reload the config, or just Cmd + R
# more default key bindings: http://w.yet.org/posts/2024-12-30-ghostty/
keys-gt:
    ghostty +list-keybinds --default

sync-gt:
    mkdir -p ~/.config/
    rm ~/.config/ghostty || true
    ln -s {{justfile_directory()}}/dotfiles/.config/ghostty ~/.config/ghostty

reset-gt:
    rm ~/.config/ghostty

stylua:
    stylua *.lua

sync-nvim: stylua
    #!/usr/bin/env bash
    mkdir -p ~/.config/nvim
    cp -f init.lua ~/.config/nvim/init.lua

sync-plugins: stylua
    mkdir -p ~/.config/nvim/lua/plugins/
    cp -f uts-plugins.lua ~/.config/nvim/lua/plugins/spec.lua

sync-lvim: stylua sync-nvim
    mkdir -p ~/.config/lvim
    cp -f init.lua ~/.config/lvim/nvim-init.lua
    cp -f uts-plugins.lua ~/.config/lvim/uts-plugins.lua
    cp -f config.lua ~/.config/lvim/config.lua

sync-lazyvim: stylua sync-plugins
    mkdir -p ~/.config/lazyvim
    cp -f init.lua ~/.config/lazyvim/lua/config/options.lua
    # cp -f lazyvim-init.lua ~/.config/lazyvim/lazyvim-init.lur

sync-chad: stylua sync-plugins
    mkdir -p ~/.config/nvchad/
    cp -f init.lua ~/.config/nvchad/nvim-init.lua
    cp -f lazyvim-init.lua ~/.config/nvchad/nvchad-init.lua

prep-nvim: prep-term
    #!/usr/bin/env bash
    which nvim || brew install neovim
    # rip ~/.config/nvim
    # git clone https://github.com/ntk148v/neovim-config.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim

@nvim PROJ="forest" *PARAMS="": sync-nvim
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim {{PARAMS}}

prep-lvim: prep-term prep-nvim
    #!/usr/bin/env bash
    # rip ~/.cache/lvim ~/.bun/install ~/.local/share/lunarvim ~/.config/lvim/
    # bun upgrade
    yes|bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)
    just add-zrc 'export PATH=$HOME/.local/bin:$PATH'
    just sync-lvim
    (cd ~/.config/lvim/ && lvim --headless +'lua require("lvim.utils").generate_settings()' +qa && sort -o lv-settings.lua{,} )
    echo
    echo "Use lvim to start LunarVim"

@lvim PROJ="forest" *PARAMS="": sync-lvim
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}} && lvim {{PARAMS}}

prep-lazyvim:
    #!/usr/bin/env bash
    if [ -d ~/.config/lazyvim ]; then
        (cd ~/.config/lazyvim && git pull)
    else
        git clone https://github.com/LazyVim/starter ~/.config/lazyvim
    fi

@lazyvim PROJ="forest": sync-lazyvim
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim --cmd 'set runtimepath+=~/.config/lazyvim/' --cmd 'lua package.path = package.path .. ";{{home_directory()}}/.config/lazyvim/lua/?.lua"' -u ~/.config/lazyvim/init.lua

prep-chad:
    #!/usr/bin/env bash
    if [ -d ~/.config/nvchad ]; then
        (cd ~/.config/nvchad && git pull)
    else
        git clone https://github.com/NvChad/starter ~/.config/nvchad
    fi

@chad PROJ="forest": sync-chad
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim --cmd 'set runtimepath+=~/.config/nvchad/' --cmd 'lua package.path = package.path .. ";{{home_directory()}}/.config/nvchad/lua/?.lua"' -u ~/.config/nvchad/nvchad-init.lua

yazi DIR="{{HOME}}/projects":
    #!/usr/bin/env bash
    EDITOR=lvim yazi {{DIR}}

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

prep-monit:
    #!/usr/bin/env zsh
    # which glances || brew install glances
    which btop || brew install btop
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

rec:
    uvx asciinema rec

add-zrc LINE:
    grep -F '{{LINE}}' ~/.zshrc || echo '{{LINE}}' >> ~/.zshrc

add-brc LINE:
    grep -F '{{LINE}}' ~/.bashrc || echo '{{LINE}}' >> ~/.bashrc

# Copy and paste to run in zsh, because we have no just at this point
# Next, run: just prep-term
# Then, maybe run: just mk-act
# So the work can be continued in the Ubuntu container
bootstrap-centos:
    #!/usr/bin/env zsh
    yes|sudo yum groupinstall 'Development Tools'
    yes|sudo yum install procps-ng curl file git
    yes|/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    yes|sudo yum install util-linux-user
    which node || brew install node
    yes|sudo yum install -y gtk2-devel openssl-devel
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    brew install just
    just add-zrc 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    just chsh
    just prep-term

# Copy and paste to run in zsh, because we have no just at this point
bootstrap-mac:
    #!/usr/bin/env zsh
    xcode-select --install
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew install just
    mkdir -p ~/projects
    cd ~/projects && git clone https://github.com/utensil/forest
    cd forest
    just add-zrc 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    just prep-term

chsh:
    # chsh -s `chsh -l|grep zsh|head -1` `whoami`
    # chsh -s `which zsh` `whoami`

prep-ubuntu:
    sudo apt update
    sudo apt install -y build-essential curl file git
    yes|/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    just add-zrc 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    just add-brc 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    sudo apt install -y zsh

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

# manually run bootstrp-ubuntu first, or we won't even have just
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

prep-lvim-in-zsh:
    #!/usr/bin/env zsh
    just prep-lvim

mk-rp:
    sudo docker run -d --privileged --name rp-dev -v{{justfile_directory()}}:/root/projects/forest runpod/pytorch:2.2.1-py3.10-cuda12.1.1-devel-ubuntu22.04 bash -c 'sleep infinity'

run-rp:
    sudo docker exec -it -w /root/projects/forest rp-dev bash

# Copy and paste to run, because we have no just at this point
# Next, run: just prep-act
bootstrp-ubuntu:
    #!/usr/bin/env bash
    apt update
    apt install -y build-essential curl file git sudo
    wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1> /dev/null
    echo "deb [arch=all,$(dpkg --print-architecture) signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list
    sudo apt update
    sudo apt install -y just

prep-chisel:
    #!/usr/bin/env bash
    which chisel || (curl https://i.jpillora.com/chisel! | bash)

# default ports are ordered so it's clear that local nvim -> local 1212 -> mid 1213 -> remote nvim 1214
# authenticated by environment variable AUTH user:pass

cs-remote PORT="1213":
    chisel server -v --port {{PORT}}

cs_mid := env("CS_MID", "localhost:1213")

cs-local MID=cs_mid LOCAL="1212" TARGET="1214":
    chisel client -v http://{{MID}} {{LOCAL}}:{{TARGET}}

nv-remote PROJ="forest" PORT="1214":
    just nvim {{PROJ}} --embed --listen localhost:{{PORT}}

nv-local PROJ="forest" PORT="1212":
    just nvim {{PROJ}} --server localhost:{{PORT}} --remote-ui

# an alternative is use local on CentOS and remote on Ubuntu in docker, no chisel needed, just docekr port mapping
lv-remote PROJ="forest" PORT="1214":
    #!/usr/bin/env zsh
    just lvim {{PROJ}} --embed --listen 0.0.0.0:{{PORT}}

lv-local PROJ="forest" PORT="1214":
    #!/usr/bin/env zsh
    just lvim {{PROJ}} --server localhost:{{PORT}} --remote-ui

prep-rust:
    #!/usr/bin/env bash
    set -e
    which cargo || (
        (curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly) &&
        (just add-zrc '. $HOME/.cargo/env' && echo 'Run: . $HOME/.cargo/env')
    )
    . $HOME/.cargo/env
    which cargo-binstall || cargo install cargo-binstall

# a zsh that inherits .env
zsh:
    zsh

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

loc:
    tokei -o json|uvx tokei-pie

prep-date:
    which git-backdate || (curl https://raw.githubusercontent.com/rixx/git-backdate/main/git-backdate > /usr/local/bin/git-backdate && chmod +x /usr/local/bin/git-backdate)
    which gdate || brew install coreutils

date: prep-date
    #!/usr/bin/env zsh
    BEGIN_DATE=$(gdate -d "3 days ago" +%Y-%m-%d)
    END_DATE=$(gdate -d "today" +%Y-%m-%d)
    echo "Rewriting history to distribute commits between ${BEGIN_DATE} and ${END_DATE}"
    git backdate origin/main "${BEGIN_DATE}..${END_DATE}" --no-business-hours

# based on https://github.com/zachdaniel/dotfiles/blob/main/priv_scripts/project
proj:
    fd --type d --max-depth 1 --base-directory {{home_directory()}}/projects|fzf --prompt 'Select a directory: '|xargs -I {} kitty @ launch --type os-window --cwd {{home_directory()}}/projects/forest --copy-env zsh -c 'just lvim {}'

# to search history, use Ctrl+R instead
# here is how to search files
fzf:
    fzf --preview 'bat {}'|xargs lvim

view URL="http://localhost:1314/":
    awrit {{URL}}

prep-zsh:
    brew install zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode

# https://kasad.com/blog/zsh-profiling/
# also uncomment the lines at the start and the end of .zshrc
prof-zsh:
    time zsh -i -c exit

prep-rc:
    # copy with confirmation
    cp -i dotfiles/.envrc ~/.envrc
    cp -i dotfiles/.bashrc ~/.bashrc
    cp -i dotfiles/.zshrc ~/.zshrc

postman:
    # uv tool install --python 3.12 posting
    uvx --python 3.12 posting

prep-kopia:
    which kopia || (brew install kopia; brew install --cask kopiaui)

prep-annex:
    which git-annex || brew install git-annex
    # brew services start git-annex
    mkdir -p ~/annex
    (cd ~/annex && git annex webapp)

ghost:
    npx ghosttime

prep-base16-helix:
    #!/usr/bin/env zsh
    # if ../base16-helix doesn't exist, clone it
    if [ ! -d ../base16-helix ]; then
        git clone https://github.com/tinted-theming/base16-helix ../base16-helix
    else
        (cd ../base16-helix && git pull)
    fi
    mkdir -p ~/.config/helix/themes
    cp -f ../base16-helix/themes/base16-railscasts.toml ~/.config/helix/themes/base16-railscasts.toml

prep-hx:
    which hx || brew install helix
    rm -rf ~/.config/helix || true
    ln -s {{justfile_directory()}}/dotfiles/.config/helix ~/.config/helix
    just prep-base16-helix
    just prep-lsp-ai

sync-hx:
    hx --grammar fetch
    hx --grammar build

hx PROJ="forest":
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}}
    # export GITHUB_COPILOT_TOKEN=$(gh auth token)
    hx

# prep-hxcp:
#     which copilot-language-server || npm install -g @github/copilot-language-server
#     mkdir -p ~/.config/helix
#     cp -f dotfiles/.config/helix/languages.toml ~/.config/helix/languages.toml

prep-lsp-ai:
    which cargo || just prep-rust
    which lsp-ai || cargo install lsp-ai # -F llama_cpp -F metal
    which marksman || brew install marksman
    # mkdir -p ~/.config/helix
    # cp -f dotfiles/.config/helix/languages.toml ~/.config/helix/languages.toml

git PROJ="forest" *PARAMS="":
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}} && lazygit {{PARAMS}}


awake:
    caffeinate -d -s

# prep-pod:
#    # brew uninstall orbstack
#    which docker || brew install docker
#    brew install podman-desktop
#    docker context use default

prep-pod:
    which docker || brew install docker
    which colima || brew install colima
    docker context use default

pod CMD="start":
    colima {{CMD}}

# https://bhoot.dev/2025/cp-dot-copies-everything/
clone SRC DST:
    cp -R {{SRC}}/. {{DST}}

# https://github.com/subframe7536/Maple-font
prep-font:
    brew install --cask font-maple-mono-nf-cn


import 'dotfiles/llm.just'
import 'dotfiles/archived.just'

