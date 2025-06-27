

prep-fancycat:
    #!/usr/bin/env bash
    set -e
    which mutool || brew install mupdf
    which zig || brew install zig
    fancy_cat_dir="/tmp/fancy-cat-$(date +%s)"
    mkdir -p $fancy_cat_dir
    git clone https://github.com/freref/fancy-cat $fancy_cat_dir
    cd $fancy_cat_dir
    # 429 Too Many Requests for fetching https://codeberg.org/atman/zg/archive/v0.13.2.tar.gz
    zig build --fetch
    zig build --release=fast
    mv zig-out/bin/fancy-cat /usr/local/bin/
    rm -rf $fancy_cat_dir

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

# https://www.kelen.cc/dry/docker-hub-mirror
gal:
    #!/usr/bin/env zsh
    mkdir -p ~/home-gallery/data/config
    cd ~/home-gallery/
    alias gallery="docker run -it --rm \
      -v $(pwd)/data:/data \
      -v $HOME/Pictures/photos:/data/Pictures \
      -u $(id -u):$(id -g) \
      -p 3000:3000 docker.wanpeng.top/xemle/home-gallery:latest"
    gallery run init --source /data/Pictures
    gallery run server

prism:
    #!/usr/bin/env zsh
    mkdir -p $HOME/photoprism/storage
    cd $HOME/photoprism
    # if the file does not exist
    [ -f docker-compose.yaml ] || curl -L https://dl.photoprism.app/docker/macos/compose.yaml -o docker-compose.yaml
    # replace ~/Pictures with  ~/Pictures/photos
    sed -i '' 's|~/Pictures:|~/Pictures/photos:|g' docker-compose.yaml
    echo "Visit http://localhost:2342/, login with admin:insecure"
    docker compose up

pica:
    #!/usr/bin/env zsh
    mkdir -p $HOME/picapport
    cd $HOME/picapport
    docker run -it --rm --name picapport -p 8888:8888 -v $HOME/Pictures/photos:/opt/picapport/photos -v $HOME/picapport:/opt/picapport/data -e "PICAPPORT_PORT=8888" -e "PICAPPORT_LANG=en" fionnb/picapport:latest

# prepare raycast
prep-ray:
    #!/usr/bin/env bash
    brew install --cask raycast

prep-meet:
    brew tap zackriya-solutions/meetily
    which meetily-server || brew install --cask meetily
    meetily-download-model medium

meet LANG="zh" SIZE="medium":
    meetily-server --language {{LANG}} --model {{SIZE}}

# prep-homerow:
#    !/usr/bin/env zsh
#     which kanata || brew install kanata
#     https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/raw/refs/heads/main/dist/Karabiner-DriverKit-VirtualHIDDevice-5.0.0.pkg
#     [ -d /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS ] || (echo You need to install Karabiner VirtualHiDDevice Driver from https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/blob/main/dist/Karabiner-DriverKit-VirtualHIDDevice-5.0.0.pkg && exit 1)
#     /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
#     [ -d ../home-row-mods ] || git clone https://github.com/dreamsofcode-io/home-row-mods/ ../home-row-mods
#     cd ../home-row-mods/kanata/macos
#     sudo kanata -c kanata.kbd
