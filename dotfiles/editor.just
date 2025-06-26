# Editor/IDE Configuration Tasks
import 'term.just'

# Helix Editor
prep-hx:
    which hx || brew install helix
    rm -rf ~/.config/helix || true
    ln -s {{justfile_directory()}}/dotfiles/.config/helix ~/.config/helix
    just prep-base16-helix
    just sync-hx

sync-hx:
    hx --grammar fetch
    hx --grammar build

reset-hx:
    rm -rf ~/.config/helix || true

# -v enables verbose logging
hx PROJ="forest" *PARAMS="":
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}}
    hx {{PARAMS}}

prep-hxx:
    #!/usr/bin/env zsh
    if [ ! -d ../helix ]; then
        git clone https://github.com/utensil/helix ../helix
    else
        (cd ../helix && git checkout patchy && git pull)
    fi
    cd ../helix
    cargo clean
    cargo install --path helix-term --locked
    export HELIX_RUNTIME=$PWD/runtime
    ~/.cargo/bin/hx -g fetch
    ~/.cargo/bin/hx -g build

hxx PROJ="forest" *PARAMS="":
    #!/usr/bin/env zsh
    export HELIX_RUNTIME=~/projects/helix/runtime
    cd ~/projects/{{PROJ}}
    ~/.cargo/bin/hx

# Neovim
prep-nvim:
    #!/usr/bin/env bash
    which nvim || brew install neovim

sync-nvim:
    #!/usr/bin/env bash
    mkdir -p ~/.config/nvim
    cp -f init.lua ~/.config/nvim/init.lua

nvim PROJ="forest" *PARAMS="": sync-nvim
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim {{PARAMS}}

# LunarVim
prep-lvim: prep-term prep-nvim
    #!/usr/bin/env bash
    yes|bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)
    just add-zrc 'export PATH=$HOME/.local/bin:$PATH'
    just sync-lvim
    (cd ~/.config/lvim/ && lvim --headless +'lua require("lvim.utils").generate_settings()' +qa && sort -o lv-settings.lua{,} )
    echo "Use lvim to start LunarVim"

sync-lvim: stylua sync-nvim
    mkdir -p ~/.config/lvim
    cp -f init.lua ~/.config/lvim/nvim-init.lua
    cp -f uts-plugins.lua ~/.config/lvim/uts-plugins.lua
    cp -f config.lua ~/.config/lvim/config.lua

lvim PROJ="forest" *PARAMS="": sync-lvim
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}} && lvim {{PARAMS}}

# LazyVim
prep-lazyvim:
    #!/usr/bin/env bash
    if [ -d ~/.config/lazyvim ]; then
        (cd ~/.config/lazyvim && git pull)
    else
        git clone https://github.com/LazyVim/starter ~/.config/lazyvim
    fi

sync-lazyvim: stylua sync-plugins
    mkdir -p ~/.config/lazyvim
    cp -f init.lua ~/.config/lazyvim/lua/config/options.lua

lazyvim PROJ="forest": sync-lazyvim
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim --cmd 'set runtimepath+=~/.config/lazyvim/' --cmd 'lua package.path = package.path .. ";{{home_directory()}}/.config/lazyvim/lua/?.lua"' -u ~/.config/lazyvim/init.lua

# NvChad
prep-chad:
    #!/usr/bin/env bash
    if [ -d ~/.config/nvchad ]; then
        (cd ~/.config/nvchad && git pull)
    else
        git clone https://github.com/NvChad/starter ~/.config/nvchad
    fi

sync-chad: stylua sync-plugins
    mkdir -p ~/.config/nvchad/
    cp -f init.lua ~/.config/nvchad/nvim-init.lua
    cp -f lazyvim-init.lua ~/.config/nvchad/nvchad-init.lua

chad PROJ="forest": sync-chad
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim --cmd 'set runtimepath+=~/.config/nvchad/' --cmd 'lua package.path = package.path .. ";{{home_directory()}}/.config/nvchad/lua/?.lua"' -u ~/.config/nvchad/nvchad-init.lua

# AstroNvim
prep-astro:
    #!/usr/bin/env zsh
    if [ -d ~/.config/astro ]; then
        (cd ~/.config/astro && git pull)
    else
        git clone https://github.com/AstroNvim/template ~/.config/astro
    fi

sync-astro: stylua sync-plugins
    mkdir -p ~/.config/astro/lua/
    cp -f dotfiles/.config/astro/lua/community.lua ~/.config/astro/lua/
    mkdir -p ~/.config/astro/lua/plugins
    cp -f dotfiles/.config/astro/lua/plugins/spec.lua ~/.config/astro/lua/plugins/spec.lua

astro PROJ="forest": sync-astro
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}} && NVIM_APPNAME=astro nvim .

# https://docs.astronvim.com/reference/alt_install/

try-astro:
    #!/usr/bin/env zsh
    if docker ps -a | grep -q astro; then
        if ! docker ps | grep -q astro; then
            docker start astro
        fi
        docker exec -it astro sh
    else
        docker run --name astro -w /root -it alpine:edge sh -uelic '
        apk add bash curl git lua nodejs npm lazygit bottom python3 go neovim ripgrep alpine-sdk --update
        # Replace with your own configuration repository to load a user configuration
        [ ! -d ~/.config/nvim ] && git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
        sh
        '
    fi

# Language Servers
prep-lsp:
    which pylsp || brew install python-lsp-server
    which ruff || brew install ruff
    which typescript-language-server || brew install typescript-language-server
    which cargo || just prep-rust
    which rust-analyzer || (rustup component add rust-src; rustup component add rust-analyzer)
    which zls || echo "zls not installed, visit https://zigtools.org/zls/install/"

# https://github.com/DJAndries/llmvm/tree/master/frontends/codeassist
prep-lsp-lv:
    #!/usr/bin/env zsh
    set -e
    which llmvm-codeassist || (cargo install llmvm-core llmvm-codeassist llmvm-outsource)
    echo "openai_endpoint=\"$OPENAI_API_BASE\"\nopenai_api_key=\"$OPENAI_API_KEY\"" > ~/Library/Application\ Support/com.djandries.llmvm/outsource.toml
    echo "model=\"outsource/openai-chat/$OPENAI_API_MODEL\"\nprompt_template_id=\"codegen\"\nmax_tokens=8192" > ~/Library/Application\ Support/com.djandries.llmvm/presets/$OPENAI_API_MODEL.toml
    echo "default_preset=\"$OPENAI_API_MODEL\"" > ~/Library/Application\ Support/com.djandries.llmvm/codeassist.toml

prep-lsp-ai:
    which cargo || just prep-rust
    which lsp-ai || cargo install lsp-ai
    which marksman || brew install marksman

# prep-hxcp:
#     which copilot-language-server || npm install -g @github/copilot-language-server
#     mkdir -p ~/.config/helix
#     cp -f dotfiles/.config/helix/languages.toml ~/.config/helix/languages.toml

# Editor Plugins
sync-plugins: stylua
    mkdir -p ~/.config/nvim/lua/plugins/
    cp -f uts-plugins.lua ~/.config/nvim/lua/plugins/spec.lua

# Stylua
stylua:
    stylua *.lua

# Base16 Themes for Helix
prep-base16-helix:
    #!/usr/bin/env zsh
    if [ ! -d ../base16-helix ]; then
        git clone https://github.com/tinted-theming/base16-helix ../base16-helix
    else
        (cd ../base16-helix && git pull)
    fi
    mkdir -p ~/.config/helix/themes
    cp -f ../base16-helix/themes/base16-railscasts.toml ~/.config/helix/themes/base16-railscasts.toml
