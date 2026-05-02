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

prep-switch:
    [ -d /Applications/InstantSpaceSwitcher.app ] || brew install --cask jurplel/tap/instant-space-switcher
    just uq /Applications/InstantSpaceSwitcher.app

# A terminal-based battery and energy monitor for macOS and Linux.
# But it crashes for now, issue: https://github.com/jordond/jolt/issues/114
#
prep-jolt:
    which jolt || (curl -fsSL https://getjolt.sh/install.sh | bash) # || brew install jordond/tap/jolt

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
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

bt CONTAINER_NAME:
    echo '#!/usr/bin/env bash\napt update\napt install -y build-essential curl file git sudo neovim\ncurl https://mise.run | sh\neval "$(~/.local/bin/mise activate bash)"\nmise trust\nmise use -g just\necho 'eval \"$(~/.local/bin/mise activate bash)\"' >> ~/.bashrc' | docker exec -i {{CONTAINER_NAME}} bash -s

[linux]
prep-brew:
    yes|/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
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


