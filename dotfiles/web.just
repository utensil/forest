## Browser

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

# hygg: a minimalist terminal-based document reader supporting PDFs, EPUBs, and text files with vim-like navigation
#
prep-hygg:
    which hygg || cargo install --locked hygg

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

