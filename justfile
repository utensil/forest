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

nvim:
    #!/usr/bin/env bash
    # Install FiraCode Nerd Font from https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
    # After installation, run: fc-cache -f -v
    # Default Mac terminal cannot support true color
    # Install rio: brew install --cask rio
    brew install --cask alacritty
    # configure alacritty
    # https://alacritty.org/config-alacritty.html
    cat <<EOF > $HOME/.alacritty.toml
        [font]
        normal = { family = "FiraCode Nerd Font Mono", style = "Regular" }
        size = 16
    EOF
    brew install neovim
    # rm -rf ~/.config/nvim ~/.bun/install ~/.local/share/lunarvim ~/.config/lvim/
    # git clone https://github.com/utensil/dotnvim.git ~/.config/nvim
    # git clone https://github.com/ntk148v/neovim-config.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
    # :NvCheatsheet
    # bun upgrade
    yes|bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)
    echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
    echo '. $HOME/.bashrc' >> ~/.zshrc
    # (cd ~/.config/lvim/ && lvim --headless +'lua require("lvim.utils").generate_settings()' +qa && sort -o lv-settings.lua{,} )
    cp config.lua ~/.config/lvim/
    echo 'Use lvim to start LunarVim'




# act:
#     ./act.sh
