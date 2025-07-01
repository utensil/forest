# zmodload zsh/zprof

source $HOME/.envrc

eval "$(starship init zsh)"

eval "$(zoxide init zsh)"

# https://github.com/Sin-cy/dotfiles
# run `just prep-zsh` first
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# use right arrow key to accept suggestion
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# zprof

