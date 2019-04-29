export TERM="xterm-256color"
export EDITOR="vim"
export PATH="$PATH:$(go env GOPATH)/bin"

source ~/.oh-my-zsh
source ~/.antigen/antigen.zsh

alias d10n='ssh root@167.99.246.169 -t zsh'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cp="cp -iv"     # interactive, verbose
alias rm="rm -iv"     # interactive, verbose
alias mv="mv -iv"     # interactive, verbose
alias grep="grep -i"  # ignore case
alias cat="bat"       # Set default bat
alias :q="exit"       # Quit 
alias php="php72"     # Fuckin' php versions. #TempFix
# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle command-not-found
antigen bundle tarruda/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle encode64
# Theme: powerlevel9k
## https://github.com/bhilburn/powerlevel9k
POWERLEVEL9K_INSTALLATION_PATH=$ANTIGEN_BUNDLES/bhilburn/zsh-theme-powerlevel9k
## configurations:
POWERLEVEL9K_MODE='none'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir dir_writable vcs status)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(time date)
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_FOREGROUND="white"
POWERLEVEL9K_STATUS_VERBOSE=false
POWERLEVEL9K_TIME_BACKGROUND="black"
POWERLEVEL9K_DATE_BACKGROUND="black"
POWERLEVEL9K_TIME_FOREGROUND="249"
POWERLEVEL9K_DATE_FOREGROUND="249"
POWERLEVEL9K_TIME_FORMAT="%D{%H:%M}"
POWERLEVEL9K_COLOR_SCHEME='dark'
POWERLEVEL9K_HIDE_BRANCH_ICON=true

antigen theme bhilburn/powerlevel9k powerlevel9k

# Tell antigen that you're done.
antigen apply

# these aliases need to be after antigen, otherwise they get overridden
alias ll="exa -l --git --time-style=long-iso --group-directories-first"
alias l="exa -la --git --time-style=long-iso --group-directories-first"
alias la="exa -lahg --git --time-style=long-iso --group-directories-first"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

archlinux-java get
go version
php -v
node -v

####################################################################################
# Partial match and tab highlight                                                  #
####################################################################################
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
####################################################################################
# History Configuration                                                            #
####################################################################################
HISTSIZE=1000               #How many lines of history to keep in memory
HISTFILE=~/.zsh_history     #Where to save history to disk
SAVEHIST=1000               #Number of history entries to save to disk
HISTDUP=erase               #Erase duplicates in the history file
setopt    appendhistory     #Append history to the history file (no overwriting)
setopt    sharehistory      #Share history across terminals
setopt    incappendhistory  #Immediately append to the history file, not just when a term is killed

# NSOFT
source /home/ahalac/Documents/code/dotfiles/nsoft_shell
