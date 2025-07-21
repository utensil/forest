# zmodload zsh/zprof

source $HOME/.envrc

(which starship > /dev/null) && eval "$(starship init zsh)"

(which zoxide > /dev/null) && eval "$(zoxide init zsh)"
alias cd="z"

(which atuin > /dev/null) && eval "$(atuin init zsh)"

(which mise > /dev/null) && eval "$(mise activate zsh)"

# https://github.com/Sin-cy/dotfiles
# run `just prep-zsh` first
# use right arrow key to accept suggestion
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# zprof

