export PROJECT_ROOT := justfile_directory()
export HOMEBREW_NO_AUTO_UPDATE := "1"

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
    which z || brew install zoxide
    which imagemagick ||brew install imagemagick
    grep -F 'eval "$(zoxide init zsh)"' ~/.zshrc|| echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
    # grep ~/.bashrc -F 'eval "$(starship init bash)"' || echo 'eval "$(starship init bash)"' >> ~/.bashrc
    grep -F 'eval "$(starship init zsh)"' ~/.zshrc || echo 'eval "$(starship init zsh)"' >> ~/.zshrc

prep-alacritty:
    #!/usr/bin/env bash
    # Install FiraCode Nerd Font from https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
    # After installation, run: fc-cache -f -v
    # Default Mac terminal cannot support true color
    which alacritty || brew install --cask alacritty
    # configure alacritty
    # https://alacritty.org/config-alacritty.html
    cp .alacritty.toml ~/.alacritty.toml

prep-kitty: && sync-kitty
    #!/usr/bin/env bash
    which kitty || brew install --cask kitty

@sync-kitty:
    # configure kitty
    # https://sw.kovidgoyal.net/kitty/conf.html
    mkdir -p ~/.config/kitty
    cp -f kitty.conf ~/.config/kitty/kitty.conf
    cp -f kitty_session.conf ~/.config/kitty/kitty_session.conf

[macos]
prep-warp:
    #!/usr/bin/env bash
    if [ ! -d "/Applications/Warp.app" ]; then
        brew install --cask warp
        echo "CMD+, then search for terminal, specify External: Osx Exec to Warp.app"
    fi

stylua:
    stylua *.lua

sync-nvim: stylua
    #!/usr/bin/env bash
    mkdir -p ~/.config/nvim
    cp -f init.lua ~/.config/nvim/init.lua

sync-plugins: stylua
    mkdir -p ~/.config/nvim/lua/plugins/
    cp -f uts-plugins.lua ~/.config/nvim/lua/plugins/spec.lua
    cp -f lazyvim-cmp.lua ~/.config/nvim/lua/plugins/lazyvim-cmp.lua

sync-lvim: stylua sync-nvim sync-kitty
    mkdir -p ~/.config/lvim
    cp -f init.lua ~/.config/lvim/nvim-init.lua
    cp -f uts-plugins.lua ~/.config/lvim/uts-plugins.lua
    cp -f config.lua ~/.config/lvim/config.lua

sync-lazyvim: stylua sync-plugins
    mkdir -p ~/.config/lazyvim
    cp -f init.lua ~/.config/lazyvim/nvim-init.lua
    cp -f lazyvim-init.lua ~/.config/lazyvim/lazyvim-init.lua

sync-chad: stylua sync-plugins
    mkdir -p ~/.config/nvchad/
    cp -f init.lua ~/.config/nvchad/nvim-init.lua
    cp -f lazyvim-init.lua ~/.config/nvchad/nvchad-init.lua

prep-nvim: prep-term
    #!/usr/bin/env bash
    which nvim || brew install neovim
    # rip ~/.config/nvim
    # git clone https://github.com/ntk148v/neovim-config.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim

@nvim PROJ="forest": sync-nvim
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim

prep-lvim: prep-term prep-nvim
    #!/usr/bin/env bash
    # rip ~/.cache/lvim ~/.bun/install ~/.local/share/lunarvim ~/.config/lvim/
    # bun upgrade
    yes|bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)
    echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
    echo '. $HOME/.bashrc' >> ~/.zshrc
    just sync-nvim
    (cd ~/.config/lvim/ && lvim --headless +'lua require("lvim.utils").generate_settings()' +qa && sort -o lv-settings.lua{,} )
    echo
    echo "Use lvim to start LunarVim"

@lvim PROJ="forest": sync-lvim
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && lvim

prep-lazyvim:
    #!/usr/bin/env bash
    if [ -d ~/.config/lazyvim ]; then
        (cd ~/.config/lazyvim && git pull)
    else
        git clone https://github.com/LazyVim/starter ~/.config/lazyvim
    fi

@lazyvim PROJ="forest": sync-lazyvim
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim --cmd 'set runtimepath+=~/.config/lazyvim/' --cmd 'lua package.path = package.path .. ";{{home_directory()}}/.config/lazyvim/lua/?.lua"' -u ~/.config/lazyvim/lazyvim-init.lua

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
    uv venv --python 3.11

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

# act:
#     ./act.sh

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

add-brc LINE:
    grep -F '{{LINE}}' ~/.bashrc|| echo '{{LINE}}' >> ~/.bashrc

prep-centos:
    yes|sudo yum groupinstall 'Development Tools'
    yes|sudo yum install procps-ng curl file git
    yes|/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    just add-brc 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
