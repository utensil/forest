# Terminal Setup Tasks

set dotenv-load

export HOMEBREW_NO_AUTO_UPDATE := "1"
# https://blog.rust-lang.org/inside-rust/2023/01/30/cargo-sparse-protocol/
# export CARGO_REGISTRIES_CRATES_IO_PROTOCOL := "sparse"
export XDG_CONFIG_HOME := home_directory() / ".config"
export TERM := "xterm-256color"

## Terminal basic CLIs
#
# TODO: break down to essentials and extra pack

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
    # just add-zrc 'eval "$(zoxide init zsh)"'
    # just add-zrc 'eval "$(starship init zsh)"'
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
    which fastfetch || brew install fastfetch
    which tty-clock || brew install tty-clock
    which duf || brew install duf
    which jq || brew install jq
    which sq || brew install sq
    which fex || (curl -sSL https://raw.githubusercontent.com/18alantom/fex/master/install.sh | bash)
    which serpl || brew install serpl
    which scooter || brew install scooter

## Ghostty

prep-gt:
    which ghostty || brew install --cask ghostty
    just sync-gt
    just prep-gtsh

prep-gtsh:
    #!/usr/bin/env bash
    mkdir -p ~/projects
    if [ ! -d ~/projects/ghostty-shaders ]; then
        git clone https://github.com/m-ahdal/ghostty-shaders ~/projects/ghostty-shaders
    else
        (cd ~/projects/ghostty-shaders && git pull) || true
    fi

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
keys-gt:
    ghostty +list-keybinds --default

sync-gt:
    mkdir -p ~/.config/
    rm ~/.config/ghostty || true
    ln -s {{justfile_directory()}}/dotfiles/.config/ghostty ~/.config/ghostty

reset-gt:
    rm ~/.config/ghostty

## Shell setup

prep-zsh:
    brew install zsh-autosuggestions zsh-syntax-highlighting
    # zsh-vi-mode

prof-zsh:
    time zsh -i -c exit

prep-rc:
    # show diff before copying (dotfiles as new, ~ as old)
    delta --color-only ~/.envrc dotfiles/.envrc || true
    delta --color-only ~/.bashrc dotfiles/.bashrc || true
    delta --color-only ~/.zshrc dotfiles/.zshrc || true
    # copy with confirmation
    cp -i dotfiles/.envrc ~/.envrc
    cp -i dotfiles/.bashrc ~/.bashrc
    cp -i dotfiles/.zshrc ~/.zshrc

add-zrc LINE:
    grep -F '{{LINE}}' ~/.zshrc || echo '{{LINE}}' >> ~/.zshrc

add-brc LINE:
    grep -F '{{LINE}}' ~/.bashrc || echo '{{LINE}}' >> ~/.bashrc


## Tmux and friends

# try Zellij
# default key bindings (I don't like them)
# Ctrl+P N to create a new pane
# Ctrl+P then direction keys to move between panes
# Ctrl+P Z to hide frames
# Ctrl+N then direction keys to resize the corrent pane towards the direction
# Ctrl+O W to manage sessions

# install Zellij, and set its visual to minimal, and keybindings to tmux
prep-zj:
    #!/usr/bin/env zsh
    which zellij || brew install zellij
    # bash <(curl -L https://zellij.dev/launch)
    if [ ! -d ~/.config/zellij ]; then
        git clone https://github.com/t3hmrman/tmux-zellij-shim-config ~/.config/zellij
    else
        (cd ~/.config/zellij && git pull)
    fi

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

# on the original tmux
# c - new window
# number - switch to window by number
#
# $ - rename current session
# . - rename current window
# , - rename current tab
zj *PARAMS:
    #!/usr/bin/env zsh
    zellij {{PARAMS}}

# Will attatch to a session if running (will attach it as a new client, all clients can see and operate on the same session)
# or killed (will resurrect it, each pane will remember the last running command and wait for confirm to run)
at NAME="mon":
    (zellij ls|grep {{NAME}}) && just zj a {{NAME}} || just zj -s {{NAME}}

# runf SESSION="mon" CMD="zsh":
#     zellij run -f -n {{SESSION}} -- {{CMD}}

# to exit, Ctrl+B then :kill-session
# to move to left pane, Ctrl+B then left arrow
# to detach, Ctrl+B then d
prep-tmux:
    which tmux || brew install tmux

# adapted from https://maxscheijen.github.io/posts/managing-tmux-sessions-with-fzf/
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

tm-btop:
    #!/usr/bin/env zsh
    tmux attach -t btop || tmux new-session -s btop -d 'btop || zsh' \; \
      attach

tm-mon:
    #!/usr/bin/env zsh
    tmux attach -t mon || tmux new-session -s mon -d 'macmon || zsh' \; \
      split-window -v -p 50 'sudo mactop || zsh' \; \
      attach

tm-dev:
    #!/usr/bin/env zsh
    tmux attach -t dev || tmux new-session -s dev -d 'just dev || zsh' \; \
      split-window -h -p 50 'just cpa || zsh' \; \
      select-pane -t 0 \; \
      split-window -v -p 25 -t 0 'just awake || zsh' \; \
      attach

# works for mon running btop
# not really working for nvim etc.
# diss-at SESSION="main":
#     diss -e g -a {{SESSION}} zsh

# https://github.com/kovidgoyal/kitty/issues/391#issuecomment-778703119
# persistent session: abduco
# multiplexer: dvtm
# Creating a session
# just tach -c name zsh
# Ctrl+\ to detach, or use -e ^q to use Ctrl+q
# Attaching to a session
# BUT can't detach from within Helix
# just tach -a name
prep-abduco:
    which abduco || brew install abduco

abduco *PARAMS:
    abduco {{PARAMS}}
