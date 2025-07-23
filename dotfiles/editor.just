# Editor/IDE Configuration Tasks

## Helix Editor

prep-scls:
    which simple-completion-language-server || cargo install --git https://github.com/estin/simple-completion-language-server.git
    simple-completion-language-server fetch-external-snippets || true

prep-hx:
    which hx || brew install helix --HEAD
    just prep-hx-conf
    hx --grammar fetch
    hx --grammar build

prep-hx-conf:
    just reset-hx-conf
    mkdir -p ~/.config
    ln -sf {{justfile_directory()}}/dotfiles/.config/helix ~/.config/helix
    ls -lhta ~/.config/helix
    just prep-base16-helix
    just prep-scls

reset-hx-conf:
    rm -f ~/.config/helix || true

reset-hx:
    brew uninstall helix || true

reset-hxx:
    cargo uninstall helix-term || true

# -v enables verbose logging
#
hx PROJ="forest" *PARAMS="":
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}}
    hx {{PARAMS}}

# doc: https://docs.helix-editor.com/master/
#
prep-hxx:
    #!/usr/bin/env zsh
    just prep-hx-conf
    just clone utensil helix
    # sometimes we may need to delete and retrack
    # git checkout personal
    # git branch -d patchy
    # git checkout --track origin/patchy
    cd ~/projects/helix
    git checkout patchy && git pull
    # cargo clean
    cargo install --path helix-term # --locked
    export HELIX_RUNTIME=$PWD/runtime
    ~/.cargo/bin/hx -g fetch
    ~/.cargo/bin/hx -g build

hxx PROJ="forest" *PARAMS="":
    #!/usr/bin/env zsh
    export HELIX_RUNTIME=~/projects/helix/runtime
    cd ~/projects/{{PROJ}}
    ~/.cargo/bin/hx

# Base16 Themes for Helix
#
prep-base16-helix:
    #!/usr/bin/env zsh
    just clone tinted-theming base16-helix
    mkdir -p ~/.config/helix/themes
    cp -f ../base16-helix/themes/base16-railscasts.toml ~/.config/helix/themes/base16-railscasts.toml

## Neovim

prep-nvim:
    which nvim || brew install neovim
    which luarocks || brew install luarocks
    # luarocks --local --lua-version=5.1 install magick
    which stylua || brew install stylua

sync-nvim:
    #!/usr/bin/env bash
    mkdir -p ~/.config/nvim
    cp -f init.lua ~/.config/nvim/init.lua

nvim PROJ="forest" *PARAMS="": sync-nvim
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim {{PARAMS}}

## Nvim plugins
#
sync-plugins: stylua
    mkdir -p ~/.config/nvim/lua/plugins/
    cp -f uts-plugins.lua ~/.config/nvim/lua/plugins/spec.lua

# Run stylua for *.lua
stylua:
    stylua *.lua

## LunarVim

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

## LazyVim

prep-lazyvim:
    #!/usr/bin/env bash
    just clone-conf lazyvim LazyVim starter

sync-lazyvim: stylua sync-plugins
    mkdir -p ~/.config/lazyvim
    cp -f init.lua ~/.config/lazyvim/lua/config/options.lua

lazyvim PROJ="forest": sync-lazyvim
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim --cmd 'set runtimepath+=~/.config/lazyvim/' --cmd 'lua package.path = package.path .. ";{{home_directory()}}/.config/lazyvim/lua/?.lua"' -u ~/.config/lazyvim/init.lua

## NvChad

prep-chad:
    #!/usr/bin/env bash
    just clone-conf nvchad NvChad starter

sync-chad: stylua sync-plugins
    mkdir -p ~/.config/nvchad/
    cp -f init.lua ~/.config/nvchad/nvim-init.lua
    cp -f lazyvim-init.lua ~/.config/nvchad/nvchad-init.lua

chad PROJ="forest": sync-chad
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim --cmd 'set runtimepath+=~/.config/nvchad/' --cmd 'lua package.path = package.path .. ";{{home_directory()}}/.config/nvchad/lua/?.lua"' -u ~/.config/nvchad/nvchad-init.lua

## AstroNvim

prep-astro:
    #!/usr/bin/env zsh
    just clone-conf astro AstroNvim template

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

## Zed editor

prep-zed:
    #!/usr/bin/env zsh
    [[ -f /Applications/Zed.app/Contents/MacOS/zed ]] || brew install --cask zed@preview

## LSP: programming languages

prep-lsp:
    # html, css, json, eslint
    # css ls enables color swatches in helix
    which vscode-css-language-server || npm i -g vscode-langservers-extracted
    # python
    which pylsp || brew install python-lsp-server
    which ruff || brew install ruff
    # js & ts
    which typescript-language-server || brew install typescript-language-server
    # rust
    which cargo || just prep-rust
    which rust-analyzer || (rustup component add rust-src; rustup component add rust-analyzer)
    # zig
    # https://github.com/jdx/mise/discussions/3390 for mise
    # https://mise.jdx.dev/registry.html#registry
    which zig && (which zls || just prep-zls || echo "zls not installed, visit https://zigtools.org/zls/install/") || true
    just prep-lsp-md
    # GLSL
    which glsl_analyzer || ( cd /tmp && wget https://github.com/nolanderc/glsl_analyzer/releases/download/v1.6.0/aarch64-macos.zip && unzip aarch64-macos.zip && sudo mv bin/glsl_analyzer /usr/local/bin/)
    # KDL
    which kdl-lsp || cargo install --git https://github.com/kdl-org/kdl-rs kdl-lsp --locked

# https://github.com/zigtools/zls/issues/2402
#
prep-zls:
    #!/usr/bin/env zsh
    set -e
    which zig || (echo "zig not found in this environment, failed to install zls" && exit 1)
    ZIG_VERSION=`zig version`
    ZIG_VERSION_ESCAPED=`echo $ZIG_VERSION|sed -e 's/\+/%2B/g'`
    # ZIG_ARCH=`zig env|jq -r '.target | split(".")[0]'`
    # echo "$ZIG_VERSION $ZIG_VERSION_ESCAPED $ZIG_ARCH"
    # curl "https://releases.zigtools.org/v1/zls/select-version?zig_version=$ZIG_VERSION_ESCAPED&compatibility=only-runtime"|jq ".\"$ZIG_ARCH\""
    ZLS_VERSION=`curl "https://releases.zigtools.org/v1/zls/select-version?zig_version=$ZIG_VERSION_ESCAPED&compatibility=only-runtime"|jq -r ".version"`
    mise use -g aqua:zigtools/zls@$ZLS_VERSION

## LSP: content authoring

prep-lsp-md:
    which marksman || brew install marksman
    which markdown-oxide || brew install markdown-oxide
    # cargo binstall --git 'https://github.com/feel-ix-343/markdown-oxide' markdown-oxide

## LSP: Spellcheck

prep-harper:
    which harper-ls || brew install harper
    # requires a recent nightly, otherwise compilation will fail on an unstable feature
    # it reports too many spell errors from links and code, making it unsable
    # pretty output, though, thanks to https://docs.rs/crate/ariadne
    which harper-cli || cargo +nightly install --git https://github.com/Automattic/harper harper-cli --locked

prep-codebook:
    which codebook-lsp || cargo install codebook-lsp

## LSP: AI

# https://github.com/DJAndries/llmvm/tree/master/frontends/codeassist
#
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

# prep-hxcp:
#     which copilot-language-server || npm install -g @github/copilot-language-server
#     mkdir -p ~/.config/helix
#     cp -f dotfiles/.config/helix/languages.toml ~/.config/helix/languages.toml
