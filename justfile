import 'dotfiles/config.just'
import 'dotfiles/term.just'
import 'dotfiles/editor.just'

export PROJECT_ROOT := justfile_directory()

default:
    just --list
    @echo '💡 To initialize just aliases: source alias.sh'

## Forester build

new +PARAMS:
    ./new.sh {{PARAMS}}

hn +PARAMS:
    hx `just new {{PARAMS}}`

init: prep
    #!/usr/bin/env bash
    bun install
    just thm

# should run `just init` first
#
# Build forest
build:
    ./build.sh

dev:
    ./dev.sh

lize:
    ./lize.sh

fize:
    ./fize.py

thm:
    ./thm.sh

prep:
    ./prep.sh

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

## Lint

chk:
    ./chk.sh

pre-push:
    just chk

# run 'just pre-push' before every push
# This will run 'just pre-push' before every push, and may block pushes if checks fail, run 'just unprep-push' to disable
#
# Set up Git pre-push hook
prep-push:
    #!/usr/bin/env bash
    echo "Setting up Git pre-push hook..."
    echo "This will run 'just pre-push' before every 'git push'"
    echo "If checks fail, the push will be blocked"
    echo "Run 'just unprep-push' to remove this hook if needed"
    echo ""

    cat > .git/hooks/pre-push << 'EOF'
    #!/bin/sh

    # Git pre-push hook to run just pre-push
    # This will run before every git push

    echo "Running pre-push checks..."

    # Run just pre-push
    if ! just pre-push; then
        echo "Pre-push checks failed. Push aborted."
        exit 1
    fi

    echo "Pre-push checks passed."
    exit 0
    EOF

    chmod +x .git/hooks/pre-push
    echo "✅ Git pre-push hook installed successfully"
    echo "Now 'git push' will automatically run 'just pre-push' first"

# Remove Git pre-push hook
unprep-push:
    #!/usr/bin/env bash
    if [ -f .git/hooks/pre-push ]; then
        rm .git/hooks/pre-push
        echo "✅ Git pre-push hook removed"
        echo "Pushes will no longer run automatic checks"
    else
        echo "ℹ️  No pre-push hook found - nothing to remove"
    fi

prep-shellcheck:
    which shellcheck || brew install shellcheck

shellcheck:
    shellcheck *.sh

proselint FILE="":
    #!/usr/bin/env bash
    # Fuzzy find FILE and pass it to proselint
    if [[ -n "{{FILE}}" ]]; then
        uvx proselint "{{FILE}}"
    else
        local file
        file=$(fzf --height 40% --reverse --preview 'bat --color=always {}' --preview-window right:60%)
        if [[ -n "$file" ]]; then
            uvx proselint "$file"
        fi
    fi

## Enrich contents

# Inspired by https://github.com/Ranchero-Software/NetNewsWire/issues/978#issuecomment-1320911427
#
rss-stars *PARAMS:
    #!/usr/bin/env bash
    cd ~/Library/Containers/com.ranchero.NetNewsWire-Evergreen/Data/Library/Application\ Support/NetNewsWire/Accounts/2_iCloud
    # get a JSON of all the starred items with only title, url, externalURL, datePublished
    sqlite3 DB.sqlite3 '.mode json' 'select a.*, s.* from articles a join statuses s on a.articleID = s.articleID where s.starred = 1 order by s.dateArrived' |jq -r '.[]|{title, url, externalURL, datePublished, dateArrived, uniqueID}'

stars *PARAMS="--days 7":
    just rss-stars {{PARAMS}}|./stars.py {{PARAMS}}

til:
    ./til.py --reset && ./til.py

# relies on GITHUB_ACCESS_TOKEN
#
gh2md REPO OUTPUT *PARAMS="--no-prs":
    #!/usr/bin/env bash
    GITHUB_ACCESS_TOKEN=$(gh auth token) uvx gh2md --idempotent {{PARAMS}} {{REPO}} {{OUTPUT}}
    # https://github.com/mattduck/gh2md/issues/39
    # docker run --rm -it -e GITHUB_ACCESS_TOKEN=$(gh auth token) dockerproxy.net/library/python:3.11.2 bash -c 'pip install gh2md && gh2md --idempotent {{REPO}} {{OUTPUT}}'

## OS related

# Copy and paste to run in zsh, because we have no just at this point
# Next, run: just prep-term
# Then, maybe run: just mk-act
# So the work can be continued in the Ubuntu container
#
bt-centos:
    #!/usr/bin/env bash
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

# 1. Cmd+Space then enter Term, hit enter
# 2. Cmd++ to make the font and the terminal window bigger
# 3. Enter zsh
# 4. Copy and paste to run, because we have no just at this point
#
bt-mac:
    #!/usr/bin/env bash
    xcode-select --install
    # export HTTP_PROXY=
    # export HTTPS_PROXY=$HTTP_PROXY
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    brew install just
    mkdir -p ~/projects
    cd ~/projects && git clone https://github.com/utensil/forest
    cd forest
    just prep-rc
    brew install --cask ghostty@tip
    just prep-proxy
    just prep-zsh
    echo "Now, open ghostty and run `just init-mac`"

init-mac:
    just prep-font
    just prep-gt
    just sync-gt
    just prep-rust
    just prep-uv
    just prep-node
    just prep-term
    just prep-monit
    just prep-loop
    # might need sudo or human interaction
    just prep-file
    just prep-def
    just prep
    just prep-git
    just prep-delta
    echo "You may set the wallpapar to Sonoma Horizon, and use it as the screensaver"
    echo "Otherwise, visit https://wallpaperaccess.com/4k-mountain for wallpapers of mountains, and set the screensaver to Photos with the style of Ken Burns"

prep-proxy:
    #!/usr/bin/env bash
    set -e
    echo "Enter the proxy URL (e.g. http://proxy.example.com:8080):"
    read proxy_url
    echo "HTTP_PROXY=$proxy_url" >> .env
    echo "HTTPS_PROXY=$proxy_url" >> .env

prep-proxy-ui:
    # docker run --rm -it -p 5080:80 dockerproxy.net/haishanh/yacd
    docker run --rm -it -p 5080:80 ghcr.io/haishanh/yacd:master

# see https://macos-defaults.com/ and https://github.com/Swiss-Mac-User/macOS-scripted-setup and https://github.com/mathiasbynens/dotfiles/blob/main/.macos
#
prep-def:
    #!/usr/bin/env bash
    set -e
    osascript -e 'tell application "System Preferences" to quit'
    # Dock preferences
    defaults write com.apple.dock "orientation" -string "left"
    defaults write com.apple.dock "tilesize" -int "36"
    defaults write com.apple.dock "autohide" -bool "true"
    defaults write com.apple.dock "mru-spaces" -bool "false"
    # Automatically open a new Finder window when a volume is mounted
    defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
    defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
    defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true
    # Show quit for Finder
    # defaults write com.apple.finder "QuitMenuItem" -bool "true"
    # Show extensions, hidden files, path bar, sort folders first
    defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true"
    defaults write com.apple.finder "AppleShowAllFiles" -bool "true"
    defaults write com.apple.finder "ShowPathbar" -bool "true"
    defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"
    # Show nothing on desktop
    defaults write com.apple.finder "CreateDesktop" -bool "false"
    defaults write com.apple.finder "ShowExternalHardDrivesOnDesktop" -bool "false"
    defaults write com.apple.finder "ShowRemovableMediaOnDesktop" -bool "false"
    # Each display has its own space
    defaults write com.apple.spaces "spans-displays" -bool "true"
    # Save to disk (not to iCloud) by default
    defaults write NSGlobalDomain "NSDocumentSaveNewDocumentsToCloud" -bool "false"
    # Don't be too smart during typing
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    # defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    # Trackpad: map bottom right corner to right-click
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
    defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
    defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true
    # Require password immediately after sleep or screen saver begins
    # Not working! Go to Settings - Screen Saver - Lock Screen to change accordingly
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    # Avoid creating .DS_Store files on network or USB volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    # Hot corners
    # top-right: 10: Put display to sleep
    defaults write com.apple.dock wvous-tr-corner -int 10
    # bottem-left: 5: Start screen saver
    defaults write com.apple.dock wvous-bl-corner -int 5
    # Enable the automatic update check
    defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
    # Check for software updates daily, not just once per week
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
    # Download newly available updates in background
    defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
    # Don't even install System data files & security updates
    # defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 0

    killall Dock
    killall Finder
    killall SystemUIServer
    killall cfprefsd

    sudo -v
    # Disable the sound effects on boot
    sudo nvram SystemAudioVolume=" "
    # Sleep the display after 15 minutes
    sudo pmset -a displaysleep 5
    # Disable machine sleep while charging
    sudo pmset -c sleep 0
    # Set machine sleep to 5 minutes on battery
    sudo pmset -b sleep 5

remove FILE_OR_DIR:
    #!/usr/bin/env bash
    TEMP_LOCATION="/tmp/$(whoami)-$(date +%s)-$(head -c 5 /dev/random|xxd -ps)"
    mv {{FILE_OR_DIR}} $TEMP_LOCATION
    echo "{{FILE_OR_DIR}} is temporarily moved to $TEMP_LOCATION"

prep-ubuntu:
    #!/usr/bin/env bash
    sudo apt update
    sudo apt install -y build-essential curl file git
    # this fix weird issue that $USER is root, no matter I use `su -` or ssh with non-root user
    # causing: /home/linuxbrew/.linuxbrew/Homebrew/.git: Permission denied
    export USER=`whoami`
    sudo just remove /home/linuxbrew
    just remove ~/.cache/Homebrew
    yes|/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    just prep-rc
    sudo apt install -y zsh

prep-user USER:
    #!/usr/bin/env bash
    set -e
    useradd --shell "`which bash`" {{USER}}
    mkdir ~{{USER}}
    chown -R {{USER}}.{{USER}} ~{{USER}}
    passwd {{USER}}
    echo "{{USER}} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

prep-lvim-in-zsh:
    #!/usr/bin/env bash
    just prep-lvim

mk-rp:
    sudo docker run -d --privileged --name rp-dev -v{{justfile_directory()}}:/root/projects/forest runpod/pytorch:2.2.1-py3.10-cuda12.1.1-devel-ubuntu22.04 bash -c 'sleep infinity'

run-rp:
    sudo docker exec -it -w /root/projects/forest rp-dev bash

# Copy and paste to run as root, because we have no just at this point
# Next, run: just prep-act
#
bt-ubuntu:
    #!/usr/bin/env bash
    apt update
    apt install -y build-essential curl file git sudo neovim
    curl https://mise.run | sh
    eval "$(~/.local/bin/mise activate bash)"
    mise trust
    mise use -g just
    yes|/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc

## Remote

prep-chisel:
    #!/usr/bin/env bash
    which chisel || (curl https://i.jpillora.com/chisel! | bash)

# default ports are ordered so it's clear that local nvim -> local 1212 -> mid 1213 -> remote nvim 1214
# authenticated by environment variable AUTH user:pass
#
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
#
lv-remote PROJ="forest" HOST="0.0.0.0" PORT="1214":
    #!/usr/bin/env bash
    just lvim {{PROJ}} --embed --listen {{HOST}}:{{PORT}}

lv-local PROJ="forest" HOST="localhost" PORT="1214":
    #!/usr/bin/env bash
    just lvim {{PROJ}} --server {{HOST}}:{{PORT}} --remote-ui

prep-ts:
    # brew install tailscale
    brew install homebrew/cask/tailscale-app

prep-ts-ssh:
    go install github.com/derekg/ts-ssh@main

# --list
# USER@HOST:PORT
#
ts-ssh *PARAMS:
    `go env GOPATH`/bin/ts-ssh {{PARAMS}}

prep-scp:
    which termscp || brew install veeso/termscp/termscp

scp *PARAMS:
    termscp {{PARAMS}}

## Fancy

prep-fancy:
    just prep-fetch
    which tty-clock || brew install tty-clock
    which rusty-rain || cargo install rusty-rain

[linux]
prep-sudo:
    # inside docker, it might not have sudo, but it's already root
    # to make the rest of script consistent, we need to prep-sudo
    which sudo || apt install sudo

[linux]
prep-ppa: prep-sudo
    which add-apt-repository || (sudo apt update && sudo apt install -y software-properties-common)

[linux]
prep-fetch:
    which fastfetch || brew install fastfetch || ( grep -q "Ubuntu" /etc/os-release && just prep-ppa && sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch && sudo apt update && sudo apt install -y fastfetch )

prep-tattoy:
    which tattoy || cargo install --locked --git https://github.com/tattoy-org/tattoy tattoy
    rip ~/.config/tattoy || true
    ln -s ~/projects/shader-playground/shaders {{justfile_directory()}}/dotfiles/.config/tattoy/shaders
    just link-conf tattoy

# Run fastfetch every time Enter is pressed
fetch:
    #!/usr/bin/env bash
    while true; do
        clear
        fastfetch
        read -n 1
    done

time:
    tty-clock -c -s -C 3

weather CITY:
    curl 'wttr.in/{{CITY}}'
    # ?format=3'

prep-stormy:
    which stormy || go install github.com/ashish0kumar/stormy@latest

stormy CITY:
    stormy --city {{CITY}}

matrix:
    # rusty-rain -C green -H white -s -c jap
    # Colors extracted from ANSI color 2 (green) & 7 (white)
    # theme: https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/schemes/GitHub-Dark-Default.itermcolors
    rusty-rain -C 63,185,80 -H 177,186,196 -s -c jap

ghost:
    npx -y ghosttime

rec:
    uvx asciinema rec

loc:
    tokei -o json|uvx tokei-pie

## fzf

# based on https://github.com/zachdaniel/dotfiles/blob/main/priv_scripts/project
#
proj:
    fd --type d --max-depth 1 --base-directory {{home_directory()}}/projects|fzf --prompt 'Select a directory: '|xargs -I {} kitty @ launch --type os-window --cwd {{home_directory()}}/projects/forest --copy-env zsh -c 'just lvim {}'

# to search history, use Ctrl+R instead
# here is how to search files
#
fzf:
    fzf --preview 'bat {}'|xargs lvim

## Web

prep-view:
    # awrit installation usually fails with some warning
    which awrit || brew install chase/tap/awrit || true

# rendered by headless Chromium, show as image
# issues:
# - flashes for React and WebGL
# - outputs code when mouse moves after exited by ctrl+c
#
view URL="http://localhost:1314/":
    awrit {{URL}}

prep-cha:
    which cha || brew install chawan
    just prep-rdrview
    rip ~/.config/chawan || true
    ln -s {{justfile_directory()}}/dotfiles/.config/chawan ~/.config/chawan

prep-rdrview:
    #!/usr/bin/env bash
    just clone eafer rdrview
    cd ~/projects/rdrview
    brew install libxml2
    export PATH="/opt/homebrew/opt/libxml2/bin:$PATH"
    make && sudo make install

# https://chawan.net/doc/cha/index.html
# https://chawan.net/doc/cha/config.html
# https://chawan.net/doc/cha/troubleshooting.html
# q to quit
# [] to traverse links on the page
# {} to traverse paragraphs on the page
# enter to visit link
# ctrl+l to input link
#   up/down for earlier links
#   prefix with ddg: to search with duckduckgo
# ctrl+k to search
# ,. to go back or forward in history
# U to reload
# I to view image
# opt+i toggle image
# opt+j toggle scripting
# opt+k toggle cookie
# \ toggle source
# opt+y copy page link
# yu copy cursor link
# v  select text with vim motions
# y  copy selected text
# right click menu, including select and copy text
#
cha URL:
    cha {{URL}}

# very text-ish, high contrast theme, no js, no CJK support
#
# space or + - next screen
# - - prev screen
# / - search
# up/down - prev/next link
# right - open link
# left - back
# backspace - history
# | - toggle wrap
# { } - shift the page left/right if wrap is disabled
#
# ? - help
# q - quit
#
prep-lynx:
    which lynx || brew install lynx

prep-w3m:
    which w3m || brew install w3m

prep-servo:
    # softwareupdate --install-rosetta --agree-to-license
    brew install --cask servo
    just uq /Applications/Servo.app

# rendered by headless Chromium
# texts preserved as texts, properly positioned and styled
# image, canvas pixelated
# can't recognize small button with icon
# support forest xml/xslt
#
carbon URL:
    docker run --rm -ti fathyb/carbonyl {{URL}}

# edbrowse URL
# ,p - print rendered text of the whole page, p can be omitted
# <start>,<end>p - print rendered text from line <start> to line <end>
# +3 - print 3 lines moreZ
# - - previousline (can be repeated)
# z<num> - repeat last command <num> times
# n - print current line and its line number
# g - go to the link on the line
# h - explain the last ?
# qt - quit
#
prep-ed:
    which edbrowse || brew install edbrowse

postman:
    # uv tool install --python 3.12 posting
    uvx --python 3.12 posting

# https://blog.stulta.dev/posts/annoying_json/
#
prep-bjn:
    which xh || brew install xh
    which jo || brew install jo

# e.g. just bjn "some_key[sub_key]=its value" "another_key=another value"
# https://github.com/casey/just?tab=readme-ov-file#positional-arguments
#
[positional-arguments]
bjn *PARAMS:
    #!/usr/bin/env bash
    xh --offline --print=B fake.url "$@"

## Backup

# https://www.fuse-t.org/
#
prep-fuse-t:
    brew tap macos-fuse-t/homebrew-cask
    brew install fuse-t
    brew install fuse-t-sshfs

[linux]
prep-vera:
    #!/usr/bin/env bash
    which veracrypt && echo "VeraCrypt is already installed." && exit 0
    set -e
    VERSION="$(cat /etc/os-release | grep "VERSION_ID"|sed -e 's/[^0-9.]//g')"
    echo $VERSION
    DEB_URL="https://launchpad.net/veracrypt/trunk/1.26.24/+download/veracrypt-1.26.24-Ubuntu-$VERSION-amd64.deb"
    TMP_DEB="/tmp/veracrypt-$VERSION.deb"
    curl -L "$DEB_URL" -o "$TMP_DEB"
    sudo apt install -y "$TMP_DEB"
    rm -f "$TMP_DEB"
    echo "VeraCrypt installed successfully."
    # exfatprogs is the official implementation from Samsung, replacing the older reverse-engineered exfat-utils. It offers better performance and reliability https://linux.how2shout.com/how-to-check-and-enable-exfat-support-in-ubuntu/
    apt install -y exfat-fuse exfatprogs
    which mount.exfat || ln -s /usr/sbin/mount.exfat-fuse /usr/sbin/mount.exfat
    grep exfat /etc/filesystems || echo exfat >> /etc/filesystems
    # create a test tc container using exfat and test it with
    # veracrypt --text -mnokernelcrypto --password=test --non-interactive ~/projects/forest/output/test.tc /mnt/test

# Install VeraCrypt that works with FUSE-T (on Mac)
[macos]
prep-vera:
    which veracrypt || brew install --cask veracrypt-fuse-t

# Install VeraCrypt that works with macFUSE (on Mac)
[macos]
prep-vera-kernel:
    which veracrypt || brew install --cask veracrypt

vera VOLUME MNT:
    veracrypt --text {{VOLUME}} {{MNT}} # --non-interactive --password=THE_PASSWORD -m=nokernelcrypto

vera-ro VOLUME MNT:
    veracrypt --text --mount-options=ro {{VOLUME}} {{MNT}}

vera-off MNT:
    veracrypt --text -d {{MNT}}

try-smb PATH:
    #!/usr/bin/env bash
    # -d
    #--network host
    just clone crazy-max docker-samba
    cd ~/projects/docker-samba/examples/compose/
    mkdir public
    mkdir share
    touch share/something
    rip foo
    ln -s {{PATH}} foo
    mkdir foo-baz
    docker run \
      -it --rm \
      -p 127.0.0.1:445:445 \
      -e SAMBA_LOG_LEVEL=3 \
      -v "./data:/data" \
      -v "./foo:/samba/foo" \
      --name samba ghcr.io/crazy-max/samba
    # test with: smbclient //127.0.0.1/share -U foo
    # Mac finder not working

prep-rest:
    #!/usr/bin/env bash
    # which restic || brew install restic
    which backrest || (brew tap garethgeorge/homebrew-backrest-tap
    brew install backrest)
    brew services restart backrest
    echo "visit http://127.0.0.1:9898"

mnt-rest REPO:
    #!/usr/bin/env bash
    mkdir -p ~/.mnt/{{REPO}}
    open ~/.mnt/{{REPO}}
    ~/.local/share/backrest/restic mount -r ~/.rest/{{REPO}} ~/.mnt/{{REPO}}

export DREST_HOME := join(home_directory(), ".drest")

prep-drest:
    docker pull garethgeorge/backrest:latest
    mkdir -p {{DREST_HOME}}/.backrest/config
    mkdir -p {{DREST_HOME}}/.backrest/data
    mkdir -p {{DREST_HOME}}/.backrest/cache

drest:
    # echo $DREST_HOME
    echo "Visit http://127.0.0.1:19898"
    docker run --rm -p 19898:9898 -e BACKREST_PORT=9898 -e BACKREST_DATA=/data -e XDG_CACHE_HOME=/cache -v $DREST_HOME/.backrest/config:/.config/backrest -v $DREST_HOME/.backrest/data:/data -v $DREST_HOME/.backrest/cache:/cache garethgeorge/backrest:latest

prep-kopia:
    which kopia || (brew install kopia; brew install --cask kopiaui)

prep-annex:
    which git-annex || brew install git-annex
    # brew services start git-annex
    mkdir -p ~/annex
    (cd ~/annex && git annex webapp)

# https://bhoot.dev/2025/cp-dot-copies-everything/
#
cp SRC DST:
    cp -R {{SRC}}/. {{DST}}

## Code forge

prep-fj:
    docker pull data.forgejo.org/forgejo/forgejo:10

FJ_DIR :=  join(home_directory(), ".forgejo")

fj:
    #!/usr/bin/env bash
    mkdir -p {{FJ_DIR}}/ssh
    docker run --rm -it -e USER_UID=$(id -u) -e USER_GID=$(id -g) --env-file .env -p 23000:3000 -p 2222:22 -v {{FJ_DIR}}:/data -v /etc/timezone:/etc/timezone:ro -v /etc/localtime:/etc/localtime:ro data.forgejo.org/forgejo/forgejo:10

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

## Notebook

nbview FILE:
    uvx euporie notebook {{FILE}}

# https://github.com/livebook-dev/livebook#installation
#
prep-lb:
    #!/usr/bin/env bash
    mix do local.rebar --force, local.hex --force
    yes|mix escript.install hex livebook

lb:
    LIVEBOOK_IFRAME_PORT=58081 livebook server --port 58080

## Music

# https://www.reddit.com/r/youtubedl/comments/155kkcc/youtube_music_how/
#
ytm PLAYLIST:
    #!/usr/bin/env bash
    cd ~/Music
    uvx --with 'mutagen' yt-dlp -f bestaudio --cookies-from-browser chrome -x --embed-metadata --embed-thumbnail '{{PLAYLIST}}' --output '%(uploader)s/%(title)s.%(ext)s'

prep-music:
    which cmus || brew install cmus
    which mpd || brew install mpd
    mkdir -p ~/.mpd
    cp -f dotfiles/.mpd/mpd.conf ~/.mpd/mpd.conf
    brew services restart mpd
    which mpc || brew install mpc
    which ncmpcpp || brew install ncmpcpp
    mkdir -p ~/.ncmpcpp
    cp -f dotfiles/.ncmpcpp/config ~/.ncmpcpp/config

# for keybindings, see https://github.com/ncmpcpp/ncmpcpp/blob/master/doc/bindings
# 1-9 to switch between interfaces
# = is clock
# space will add the current song to the playlist, and move to the next one, just space over all songs to add them to the playlist
# p to play/pause, <> for previous/next song, -+ for volume
# fn+backspace can be used as delete, useful to delete a song from the playlist
# 8 is visualization, space to switch visualization type
#
music:
    #!/usr/bin/env bash
    cd ~/Music
    # cmus
    mpc update
    ncmpcpp -s media_library

prep-tm:
    which protoc || brew install protobuf
    which termusic || cargo install termusic termusic-server --locked

# 2 go to artist/album layout
# enter/backspace/tab for navigation
# l or L to add one or all songs to the playlist
# d or D to delete one or all songs from the playlist
# space to play/pause
# m to change play mode, r to random
# Ctrl+H for help
# no visualization
#
tm *PARAMS="":
    termusic {{PARAMS}}

prep-ym:
    [ -d /Applications/YesPlayMusic.app ] || brew install --cask yesplaymusic

# prep-music:
#     # it doesn't support free spotify accounts
#     # which spotify_player || brew install spotify_player
#     # it's no longer available
#     # which spt || brew install spotify-tui
#     # it doesn't support free spotify accounts
#     # which ncspot || brew install ncspot
#     which code-radio || cargo install code-radio-cli

# music:
#     code-radio --no-logo --volume 5

## Tiling

# I'v configured it to use double tap opt then hold to trigger the radial menu
# direction keys to place the window in 8 directions, space to maximize, enter to center
# It's so smooth
#
prep-loop:
    #!/usr/bin/env bash
    [ -d /Applications/Loop.app ] || brew install loop

prep-space:
    #!/usr/bin/env bash
    [ -d /Applications/FlashSpace.app ] || brew install flashspace

## File

tree DIR="." LEVEL="1":
    eza --git -T -L {{LEVEL}} --hyperlink {{DIR}}

# https://yazi-rs.github.io/docs/quick-start#keybindings
# ~ - get help
# t - open a tab
# <number> - open tab <number>
# . - toggle hidden
# f - smart filter; s - search via fd; S - search via rg
# r - rename
# x - cut
# y - copy
# p - paste
# d - trash
# D - delete
# cc - copy file path; cd - copy directory; cf - copy filename; cn - copy filename w/o ext
#
yazi DIR="$HOME/projects":
    #!/usr/bin/env bash
    EDITOR=hx yazi {{DIR}}

# https://github.com/Canop/broot/blob/main/website/docs/tricks.md
#
# <stringwithoutspace> - fuzzy search the string
# enter - open file in helix
# space + verb - perform actions on the file/dir
#   verbs:
#     q - quit
#     e - open file in helix
#     pp - print file path, useful for `cmd $(br)`, don't hit enter, helix won't show, you need to type `:q` blindly to quit helix
#     up - go to parent
#
prep-br:
    which broot || brew install broot
    mkdir -p ~/.config/broot/
    cp -f dotfiles/.config/broot/conf.toml ~/.config/broot/

# Tab to switch between 2 Tab
# Cmd+Shift+. to toggle hidden files
# Cmd+Shift+P to open Command Palette
# Cmd+G to go to path
# / to search by regex, \ by substring, then up/down to navigate between search results
# Set /Users/utensil/Library/Mobile Documents/com~apple~CloudDocs to favorites for iCloud docs
# for long copy/move operations, = to open the operation queue (with per-task and per-file progress bars)
# Cmd+Y to preview a file, Cmd+Enter to select an app to open the file
# Opt+1: Volumes, 2: Favorites, 3: Recent Locations, 0: parent directories
# it supports [Disk Usage Analyzing](https://marta.sh/docs/actions/disk-usage/), but note that it's async and will be queued
# Cmd+O to open embeded terminal, useful to run git commands, `z` into recent directories, run `dua i`
# Cmd+Opt+O to close it
# See dotfiles/.config/marta/marta.marco for configuration (Cmd+, then copy-paste it)
# e.g. Cmd+Opt+G to lauch Ghostty from the current directory
# use the first letter to copy, move, rename, new folder, trash, delete etc.
#
prep-file:
    #!/usr/bin/env bash
    [ -d /Applications/Marta.app ] || brew install --cask marta
    which marta || (sudo mkdir -p /usr/local/bin/ && sudo ln -s /applications/marta.app/contents/resources/launcher /usr/local/bin/marta) || true

file LEFT RIGHT:
    #!/usr/bin/env bash
    marta --new-window {{LEFT}} {{RIGHT}}

icloud:
    just file '~/Downloads' '~/Library/Mobile\ Documents/com~apple~CloudDocs'

# Can't brew install FreeFileSync due to https://github.com/Homebrew/homebrew-cask/issues/63069,
# but actually https://github.com/Marcuzzz/homebrew-marcstap/blob/master/Casks/freefilesync.rb proves that it could work
# It's POC only, as this is outdated
#
# POC to install FreeFileSync (outdated)
prep-ffs:
    # According to the issue, as long as you open the download page, the following download will pass for a few days
    open https://freefilesync.org/download.php
    brew install Marcuzzz/homebrew-marcstap/freefilesync

prep-termscp:
    which termscp || brew install termscp

pathfind:
    npx -y pagefind --site output --serve --root-selector 'article > section'

prep-ag:
    #!/usr/bin/env bash
    which ast-grep || brew install ast-grep
    just prep-hx
    just sync-hx

# just ag '\query{$$$}'
#
ag PAT LANG="forester" DIR="trees":
    ast-grep run --config dotfiles/.config/ast-grep/sgconfig.yml --lang {{LANG}} -p '{{PAT}}' {{DIR}}

prep-semgrep:
    which semgrep || brew install semgrep

semscan:
    semgrep scan --config "p/default" --config "p/trailofbits"


# https://www.howtogeek.com/803598/app-is-damaged-and-cant-be-opened/
#
uq APP_PATH:
    xattr -d com.apple.quarantine {{APP_PATH}}

## Info and chat

prep-irc:
    which weechat || brew install weechat

irc CHANNEL:
    weechat irc://utensil@irc.libera.chat/#{{CHANNEL}}

# Add a config to ~/Library/Application Support/iamb/config.toml per https://iamb.chat/configure.html
# Login via SSO on element
# Verify by `:verify`, comparing emoji on element, and copy-paste the `:verify confirm USER/DEVICE` command on iamb
#
prep-im:
    which iamb || brew install iamb

prep-hkt-archived:
    #!/usr/bin/env bash
    # Usage:
    # hn top # for HackerNews Top stories
    # hn view 2 -c # for viewing comments on the 2nd story
    # uvx haxor-news
    which hackertea || brew install karoloslykos/tap/hackertea
    # rosetta error: failed to open elf at /lib64/ld-linux-x86-64.so.2
    # docker pull --platform linux/amd64 aome510/hackernews_tui:latest
    # fails to fetch
    which clx || brew install circumflex
    # can't see replies for hackernews and lobsters yet
    which neonmodem || (
        TIMESTAMP=`date +%s`
        mkdir -p /tmp/neonmodem-${TIMESTAMP}
        curl -sSL https://github.com/mrusme/neonmodem/releases/download/v1.0.6/neonmodem_1.0.6_darwin_arm64.tar.gz | tar -xz -C /tmp/neonmodem-${TIMESTAMP}
        sudo mv /tmp/neonmodem-${TIMESTAMP}/neonmodem /usr/local/bin
    )
    neonmodem connect --type hackernews || true
    neonmodem connect --type lobsters --url https://lobste.rs || true
    # An account is needed
    # neonmodem connect --type lemmy --url https://lemmy.ml || true

prep-hk:
    #!/usr/bin/env bash
    which hackernews_tui || cargo install --git https://github.com/utensil/hackernews-TUI --branch proxy hackernews_tui --locked
    cp -f dotfiles/.config/hn-tui.toml ~/.config/

# -i ITEM
# Open HackerNews TUI
hk *PARAMS:
    hackernews_tui {{PARAMS}}

import 'dotfiles/llm.just'
import 'dotfiles/archived.just'

# Error: Your Xcode (15.4) at /Applications/Xcode.app is too outdated.
# Please update to Xcode 16.0 (or delete it).
# Xcode can be updated from the App Store.

# Error: Your Command Line Tools are too outdated.
# Update them from Software Update in System Settings.

# If that doesn't show you any updates, run:
#   sudo rip /Library/Developer/CommandLineTools
#   sudo xcode-select --install

# Alternatively, manually download them from:
#   https://developer.apple.com/download/all/.
# You should download the Command Line Tools for Xcode 16.0.

# Error: You have not agreed to the Xcode license. Please resolve this by running:
#   sudo xcodebuild -license accept
