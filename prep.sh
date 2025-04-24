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

if ! command -v opam exec forester -- --help|head &> /dev/null; then
  brew install opam  watchexec
  opam init --auto-setup --yes
  opam update --yes
  opam pin add forester git+https://git.sr.ht/~jonsterling/ocaml-forester#56de06afe952d752c1a13fdcd8bb56c5fef9956f --yes
fi

# if pandoc is not installed
if ! command -v pandoc &> /dev/null; then
  brew install pandoc
fi

# if bun is not installed
if ! command -v bun &> /dev/null; then
  # install bun
  curl -fsSL https://bun.sh/install | bash
fi

# if just is not installed
if ! command -v just &> /dev/null; then
  # install just
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
fi

echo "✅ dependencies installed: mactex, forester, pandoc, bun, just"
# echo "💡 To initialize just aliases: source alias.sh"
