#!/bin/bash

# install nvm and node first
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
# source ~/.bashrc or source ~/.zshrc
# nvm ls-remote
# nvm install v22.9.0

# generate a randome string less than 32 characters
RANDOM_ID=$(head -c 16 /dev/urandom | xxd -p | head -c 16)

git clone https://github.com/utensil/vscode-forester.git /tmp/vscode-forester-$RANDOM_ID
cd /tmp/vscode-forester-$RANDOM_ID
git checkout dev
npm install

# npm run compile

# https://stackoverflow.com/a/54409592/200764
npm install -g vsce
yes|npx vsce package

# requires https://code.visualstudio.com/docs/setup/mac#_launching-from-the-command-line
code --install-extension /tmp/vscode-forester-$RANDOM_ID/vscode-forester-0.0.7-dev-uts.vsix
# echo "run this to clean up: rm -rf /tmp/vscode-forester-$RANDOM_ID"
rm -rf /tmp/vscode-forester-$RANDOM_ID
