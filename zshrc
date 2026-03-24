# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export TERM="xterm-256color"
export EDITOR="vim"
export PATH="$PATH:$(go env GOPATH)/bin"

export FLYCTL_INSTALL="/Users/ahalac/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

source ~/.oh-my-zsh
source ~/.antigen/antigen.zsh

alias oc='ssh -N -L 18789:127.0.0.1:18789 root@192.168.0.23'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias please="sudo"
alias cp="cp -iv"     # interactive, verbose
alias rm="rm -iv"     # interactive, verbose
alias mv="mv -iv"     # interactive, verbose
alias grep="grep -i"  # ignore case
alias cat="bat"       # Set default bat
alias :q="exit"       # Quit 
alias vi="vim"
# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle command-not-found
antigen bundle tarruda/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle encode64
antigen bundle brew
antigen bundle osx

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
POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|kubens|kubectx|oc|istioctl|kogito'

# Tell antigen that you're done.
antigen apply

# these aliases need to be after antigen, otherwise they get overridden
alias ll="exa -l --git --time-style=long-iso --group-directories-first"
alias l="exa -la --git --time-style=long-iso --group-directories-first"
alias la="exa -lahg --git --time-style=long-iso --group-directories-first"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

go version
rustup --version

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

function getArrayIndex {
    if [ -n "$BASH_VERSION" ]; then
        expr $1 - 1
    else
        echo $1
    fi
}


function createDockerGetter {
    container_type=$1
    echo "\$(docker ps | awk ' /$container_type/ {print(\$NF)} '  )"
}

function server_tmuxer_cleanup {
    unset SSH_BASE_COMMAND
    unset SERVER_COUNT
    unset DOCKER_USER
    unset DOCKER_FOLDER
    unset DOCKER_CONTAINER
    unset SESSION_BASE
    unset EXCLUDE_SERVER
}

function prod_schedulers {
    local SERVERS=(
        "root@139.59.23.118"  # scheduler-blr
        "root@164.92.225.150" # scheduler-fra
        "root@162.243.173.104" # scheduler-nyc
        "root@170.64.225.143"  # scheduler-syd
    )

    local SESSION_BASE="schedulers_prod_"
    local now_timestamp session_name

    now_timestamp=$(date +"%s")
    session_name="${SESSION_BASE}${now_timestamp}"

    # Create session and connect to the first server
    tmux new-session -d -s "$session_name" "ssh ${SERVERS[0]}"

    # Split vertically for each remaining server
    for ((i=1; i<=${#SERVERS[@]}; i++)); do
        tmux split-window -v -t "$session_name" "ssh ${SERVERS[$i]}"
        tmux select-layout -t "$session_name" even-vertical
    done

    # Finalize layout to even-vertical
    tmux select-layout -t "$session_name" even-vertical

    # Synchronize panes (so typing in one goes to all)
    tmux set-window-option -t "$session_name" synchronize-panes on

    # Attach to session
    tmux attach -t "$session_name"
}

source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/ahalac/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/ahalac/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/ahalac/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/ahalac/google-cloud-sdk/completion.zsh.inc'; fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"

. "$HOME/.local/bin/env"

# ============================================
# VS Code Shell Integration for Copilot
# Fix for terminal completion detection issue
# https://github.com/orgs/community/discussions/161238
# ============================================

# VS Code shell integration - must be at the end of .zshrc
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
    # Load VS Code shell integration if available
    [[ -f "${HOME}/.config/vscode-shell-integration.zsh" ]] && source "${HOME}/.config/vscode-shell-integration.zsh"
    
    # Disable RPROMPT in VS Code (causes detection issues)
    unset RPROMPT
    
    # Ensure simple prompt format for command detection
    # This helps Copilot detect when commands finish
    typeset -g POWERLEVEL9K_DISABLE_RPROMPT=true
    
    # Increase command timeout for longer operations
    export VSCODE_SHELL_INTEGRATION_TIMEOUT=30000
fi
