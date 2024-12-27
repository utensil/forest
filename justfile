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

prep-term: prep-kitty
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

prep-alacritty:
    #!/usr/bin/env bash
    # Install FiraCode Nerd Font from https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
    # After installation, run: fc-cache -f -v
    # Default Mac terminal cannot support true color
    which alacritty || brew install --cask alacritty
    # configure alacritty
    # https://alacritty.org/config-alacritty.html
    cp .alacritty.toml ~/.alacritty.toml

[macos]
prep-kitty: && sync-kitty
    which kitty || brew install --cask kitty

[linux]
prep-kitty:
    # no op for now
    # curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

@sync-kitty:
    #!/usr/bin/env bash
    # configure kitty
    # https://sw.kovidgoyal.net/kitty/conf.html
    mkdir -p ~/.config/kitty
    cp -f kitty.conf ~/.config/kitty/kitty.conf
    cp -f kitty_session.conf ~/.config/kitty/kitty_session.conf
    # this should make kitty reload the config
    # if env var KITTY_PID is set
    if [ -n "$KITTY_PID" ]; then
        kill -SIGUSR1 $KITTY_PID
    fi

[macos]
prep-warp:
    #!/usr/bin/env bash
    if [ ! -d "/Applications/Warp.app" ]; then
        brew install --cask warp
        echo "CMD+, then search for terminal, specify External: Osx Exec to Warp.app"
    fi

prep-wez:
    which wezterm || brew install --cask wezterm
    # brew install --cask wezterm@nightly

sync-wez:
    mkdir -p ~/.config/wezterm
    cp -f wezterm.lua ~/.config/wezterm/wezterm.lua

prep-gt:
    which ghostty || brew install ghostty

# Cmd+Ctrl+F to toggle fullscreen
# Cmd + D to split right
# Cmd + Shift + D to split bottom
# Cmd + w to close the current split
# Drag the separator to resize splits
# Cmd + Option + arrows to move between splits
# Cmd + Shift + , to reload the config
keys-gt:
    ghostty +list-keybinds --default

sync-gt:
    mkdir -p ~/.config/ghostty
    cp -f ghostty.conf ~/.config/ghostty/config

stylua:
    stylua *.lua

sync-nvim: stylua
    #!/usr/bin/env bash
    mkdir -p ~/.config/nvim
    cp -f init.lua ~/.config/nvim/init.lua

sync-plugins: stylua
    mkdir -p ~/.config/nvim/lua/plugins/
    cp -f uts-plugins.lua ~/.config/nvim/lua/plugins/spec.lua

sync-lvim: stylua sync-nvim sync-kitty
    mkdir -p ~/.config/lvim
    cp -f init.lua ~/.config/lvim/nvim-init.lua
    cp -f uts-plugins.lua ~/.config/lvim/uts-plugins.lua
    cp -f config.lua ~/.config/lvim/config.lua

sync-lazyvim: stylua sync-plugins
    mkdir -p ~/.config/lazyvim
    cp -f init.lua ~/.config/lazyvim/lua/config/options.lua
    # cp -f lazyvim-init.lua ~/.config/lazyvim/lazyvim-init.lua

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
    #!/usr/bin/env bash
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

prep-sbar:
    #!/usr/bin/env bash
    curl -L https://raw.githubusercontent.com/FelixKratz/dotfiles/master/install_sketchybar.sh | sh
    mkdir -p ~/.config/sketchybar/plugins
    cp /opt/homebrew/opt/sketchybar/share/sketchybar/examples/sketchybarrc ~/.config/sketchybar/sketchybarrc
    cp -r /opt/homebrew/opt/sketchybar/share/sketchybar/examples/plugins/ ~/.config/sketchybar/plugins/
    chmod +x ~/.config/sketchybar/plugins/*
    brew services restart felixkratz/formulae/sketchybar

# Inspired by https://github.com/FelixKratz/dotfiles
dotfiletmpdir := "/tmp/dotfiles-" + choose('8', HEX)

prep-dotfiles-tmp:
    git clone https://github.com/FelixKratz/dotfiles {{dotfiletmpdir}}

config-sbar: prep-dotfiles-tmp
    #!/usr/bin/env bash
    rm -rf ~/.config/sketchybar
    cp -r {{dotfiletmpdir}}/.config/sketchybar ~/.config/
    rm -rf {{dotfiletmpdir}}
    brew services restart felixkratz/formulae/sketchybar

sbar:
    brew services restart felixkratz/formulae/sketchybar

prep-tile: prep-amethyst

prep-skhd: prep-dotfiles-tmp
    brew install koekeishiya/formulae/skhd
    rm -rf ~/.config/skhd
    cp -r {{dotfiletmpdir}}/.config/skhd ~/.config/
    skhd --start-service

prep-yabai: prep-dotfiles-tmp prep-skhd
    brew install koekeishiya/formulae/yabai
    rm -rf ~/.config/yabai
    cp -r {{dotfiletmpdir}}/.config/yabai ~/.config/
    yabai --start-service

no-yabai:
    yabai --stop-service
    skhd --stop-service

prep-amethyst:
    brew install --cask amethyst
    cp -f .amethyst.yml ~/.amethyst.yml

prep-monit:
    #!/usr/bin/env bash
    which btop || brew install btop
    # which glances || brew install glances
    if [ "$(uname)" == "Darwin" ]; then
        if [ "$(uname -m)" == "aarch64" ]; then
            which macmon || brew install vladkens/tap/macmon
            # which neoasitop || (brew tap op06072/neoasitop && brew install neoasitop)
        else
           echo "No GPU monit tools found yet"
        fi
    fi

rec:
    uvx asciinema rec

add-zrc LINE:
    grep -F '{{LINE}}' ~/.zshrc|| echo '{{LINE}}' >> ~/.zshrc

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

@prep-sync-dir-tools: prep-rust
    which jw || (yes|cargo binstall jw)
    which rusync || (yes|cargo binstall rusync)
    which rip || (yes|cargo binstall rm-improved)

sync-dirs SRC DST:
    @just rusync-dirs {{SRC}} {{DST}}
    @just check-dirs {{SRC}} {{DST}}

rusync-dirs SRC DST: prep-sync-dir-tools
    #!/usr/bin/env bash
    echo "🚀 Initiating sync..."
    rusync {{SRC}} {{DST}}
    # using this would trigger mismatch
    # rusync --err-list {{DST}}/.rusync.err.log {{SRC}} {{DST}}

check-dirs SRC DST:
    #!/usr/bin/env bash
    echo "🔍 Checking hash..."
    date
    (cd {{SRC}} && jw -c . > .hash.jw) && echo "1. source hashed: `date`"
    (cd {{DST}} && jw -c . > .hash.jw) && echo "2. destination hashed: `date`"
    MISMATCH=`jw -D {{SRC}}/.hash.jw {{DST}}/.hash.jw`
    if [ -z "$MISMATCH" ]; then
        echo "✅ Perfect match"
    else
        echo "❌ Mismatch detected"
        if [ ${#MISMATCH} -gt 1000 ]; then
            echo "$MISMATCH"|less
        else
            echo "$MISMATCH"
        fi
    fi
    # keep them both, avoid recalculation of hash
    # only remove hash.jw file from the source
    # rip {{SRC}}/.hash.jw
    # rip {{DST}}/.hash.jw
    echo "Open {{DST}}/.hash.jw to inspect"

prep-llm:
    which aichat || brew install aichat
    which assembllm || (brew tap bradyjoslin/assembllm && brew install bradyjoslin/assembllm/assembllm)
    which cortex || echo "Visit https://cortex.so/docs/installation to download and install cortex"
    # docker pull dockerproxy.net/paulgauthier/aider-full
    cp -f aider /usr/local/bin

aider *PARAMS: prep-llm
    aider {{PARAMS}}

# Uses aider in watch mode to actively monitor and assist with code changes.
# To work with other projects:
#   1. Use `just proj` to select and open a project in a new kitty terminal
#   2. Or use `just aider ../project_name` to start aider in another directory
# I've tested that it works with `AI!`, `AI?`, and `ai!`
aw *PARAMS:
    just aider -v --watch-files {{PARAMS}}

llm-proxy *PARAMS:
    #!/usr/bin/env bash
    # uvx --python 3.11 --from 'litellm[proxy]' litellm {{PARAMS}}
    aichat --serve 0.0.0.0:4000

cpm:
    #!/usr/bin/env bash
    # if env var REFRESH_TOKEN is not set, prompt for it
    if [ -z "$REFRESH_TOKEN" ]; then
        # curl https://github.com/login/device/code -X POST -d 'client_id=01ab8ac9400c4e429b23&scope=user:email'
        # curl https://github.com/login/oauth/access_token -X POST -d 'client_id=01ab8ac9400c4e429b23&scope=user:email&device_code=YOUR_DEVICE_CODE&grant_type=urn:ietf:params:oauth:grant-type:device_code'
        echo "Please follow https://github.com/jjleng/copilot-more to set up REFRESH_TOKEN"
    fi
    if [ ! -d ../copilot-more ]; then
        (cd .. && git clone https://github.com/jjleng/copilot-more.git)
    fi
    cd ../copilot-more
    uvx peotry install
    uvx poetry run uvicorn copilot_more.server:app --port 15432

# works only for Ubuntu
[linux]
prep-cortex:
    #!/usr/bin/env bash
    curl -L https://app.cortexcpp.com/download/latest/linux-amd64-local -o cortex.deb
    sudo dpkg -i cortex.deb
    # fix broken dependencies
    sudo apt-get install -f -y

prep-coder:
    # cortex pull bartowski/DeepSeek-V2.5-GGUF
    cortex run qwen2.5-coder

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

md FILE:
    uvx markitdown "{{FILE}}"

p2t FILE:
    uvx --python 3.12 --from 'pix2text[multilingual]' p2t predict --device mps --file-type pdf -i "{{FILE}}"

prep-p2t:
    #!/usr/bin/env bash
    set -e
    # if the directory not exits
    if [ ! -d ~/.pix2text-mac ]; then
        git clone https://github.com/breezedeus/Pix2Text-Mac ~/.pix2text-mac
    fi
    cd ~/.pix2text-mac
    uv venv --python 3.12 --seed
    source ~/.pix2text/.venv/bin/activate
    pip install -r requirements.txt
    pip install pix2text[multilingual]>=1.1.0.1
    python setup.py py2app -A

# https://github.com/Byaidu/PDFMathTranslate
pzh:
    uvx pdf2zh -i

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

