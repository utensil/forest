#!/bin/bash
set -eo

# # I'm experimenting using warp as my terminal
# # if warp is not installed
# # if path /Applications/Warp.app/ not exists
# if [ ! -d "/Applications/Warp.app" ]; then
#     # install warp
#     if [[ "$OSTYPE" == "darwin"* ]]; then
#         brew install --cask warp
#         echo "CMD+, then search for terminal, specify External: Osx Exec to Warp.app"
#     fi
# fi

brew uninstall texlive || true
brew install --cask mactex

if ! which forester &> /dev/null; then
  brew install opam  watchexec
  opam init --auto-setup --yes
  opam update --yes
  opam pin add forester git+https://github.com/utensil/ocaml-forester.git#2ed9c1cab0112921eb3497cb1a5a0e2fbaa1f8cd --yes
fi

# if pandoc is not installed
if ! which pandoc &> /dev/null; then
  brew install pandoc
fi

# if bun is not installed
if ! which bun &> /dev/null; then
  # install bun
  curl -fsSL https://bun.sh/install | bash
fi

# if just is not installed
if ! which just &> /dev/null; then
  # install just
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
fi

# required by
# Opam package conf-libffi.2.0.0 depends on the following system package that can no longer be found: libffi
brew install libffi

echo "✅ dependencies installed: mactex, forester, pandoc, bun, just"
# echo "💡 To initialize just aliases: source alias.sh"
