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

# https://stackoverflow.com/a/54409592/200764
npm install -g vsce

npx vsce package
# code --install-extension my-extension-0.0.1.vsix
rm -rf /tmp/vscode-forester-$RANDOM_ID
