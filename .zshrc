# Key bindings
bindkey -e
typeset -g -A key
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[OH' beginning-of-line
bindkey '^[OF' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[5~' up-line-or-history
bindkey '^[[6~' down-line-or-history
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[C' forward-char
bindkey '^[[D' backward-char

# Useful aliases and functions
# Create a directory and cd into it
function take() {
  mkdir -p $1
  cd $1
}

# Enable auto-cd
setopt auto_cd

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt share_history
setopt hist_ignore_dups
# Arch Linux package management
alias pacupdate="sudo pacman -Syu"
alias pacinstall="sudo pacman -S"
alias pacremove="sudo pacman -Rs"
alias pacsearch="pacman -Ss"

# Environment Variables
export EDITOR=nvim

# Prompt Modification
PROMPT='%F{blue}%~%f %# '

# This loads the Zsh completion system module.
# -U flag prevents alias expansion during function loading.
# -z flag forces zsh-style autoloading.
autoload -Uz compinit
compinit

# Menu-Like Interface
zstyle ':completion:*' menu select
