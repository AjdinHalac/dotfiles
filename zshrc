# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export TERM="xterm-256color"
export EDITOR="vim"
export PATH="$PATH:$(go env GOPATH)/bin"

source ~/.oh-my-zsh
source ~/.antigen/antigen.zsh

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
alias php="php72"     # Fuckin' php versions. #TempFix
alias vi="vim"
# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle command-not-found
antigen bundle tarruda/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle encode64

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

alias c7e-staging='kubectl --kubeconfig=/home/ahalac/.kube/staging-ubercluster2 --namespace=c7e-default'
alias c7e-prod='kubectl --kubeconfig=/home/ahalac/.kube/prod-ubercluster --namespace=c7e-default'

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

function server_tmuxer {
    while getopts "s:n:u:f:c:b:e:l:" opt; do
        case $opt in 
            s)
                local SSH_BASE_COMMAND=$OPTARG
                ;;
            n)
                local SERVER_COUNT=$OPTARG
                ;;
            u)
                local DOCKER_USER=$OPTARG
                ;;
            f)
                local DOCKER_FOLDER=$OPTARG
                ;;
            c)
                local DOCKER_CONTAINER=$OPTARG
                ;;
            b)
                local SESSION_BASE=$OPTARG
                ;;
            e)
                local EXCLUDE_SERVER=$OPTARG
                ;;
            l)
                local SERVER_TMUXER_FINAL_LAYOUT=$OPTARG
                ;;
        esac
    done

    if [ -z "$SSH_BASE_COMMAND" ]; then
        echo "Missing SSH_BASE_COMMAND";
        return 1;
    fi

    if [ -z "$SERVER_COUNT" ]; then
        echo "Missing SERVER_COUNT";
        return 1;
    fi

    if [ -z "$DOCKER_CONTAINER" ]; then
        echo "Missing DOCKER_CONTAINER";
        return 1;
    fi
    if [ -z "$SESSION_BASE" ]; then
        SESSION_BASE='tmuxer_session_base'
    fi
    if [ -z "$SERVER_TMUXER_INTERMEDIATE_LAYOUT" ]; then
        SERVER_TMUXER_INTERMEDIATE_LAYOUT='even-vertical' #so babic can hack something for himself without affecting others
    fi
    if [ -z "$SERVER_TMUXER_FINAL_LAYOUT" ]; then
        SERVER_TMUXER_FINAL_LAYOUT='even-vertical'
    fi
    now_timestamp=$(date +"%s");
    session_name="$SESSION_BASE$now_timestamp";
    if [ -n "$DOCKER_USER" ]; then
        USER_PART=" -u $DOCKER_USER "
    fi
    SETUP_PART="export TERM=xterm"
    if [ -n "$DOCKER_FOLDER" ]; then
        SETUP_PART="cd $DOCKER_FOLDER && $SETUP_PART"
    fi 
    EXEC_PART="sh -c '$SETUP_PART && /bin/bash'"

    #creating session in the background
    tmux new -s $session_name -d

    local SERVERS;
    if [ -z "$EXCLUDE_SERVER" ]; then
        SERVERS=($(seq 1 $SERVER_COUNT));
    else
        SERVERS=($(seq 1 $SERVER_COUNT | egrep -v "$EXCLUDE_SERVER"));
    fi

    local REAL_SERVER_COUNT=${#SERVERS[@]}

    for ((i=1;i<$REAL_SERVER_COUNT;i++)); do
        tmux split-window -v -t $session_name && tmux select-layout -t $session_name $SERVER_TMUXER_INTERMEDIATE_LAYOUT
    done

    
    #ssh enter docker and cd
    for ((i=1;i<=$REAL_SERVER_COUNT;i++)); do
        tmux select-pane -t $(expr $i - 1)
        local index=$(getArrayIndex $i)
        local CURR_SERVER=${SERVERS[$index]};
        tmux send-keys "$SSH_BASE_COMMAND$CURR_SERVER" C-m
        tmux send-keys "docker exec -it $USER_PART $(createDockerGetter $DOCKER_CONTAINER) $EXEC_PART " C-m
    done

    #make it tiled
    tmux select-layout -t $session_name $SERVER_TMUXER_FINAL_LAYOUT

    ##synchronizing panes
    tmux set-window-option synchronize-panes

    ##entering tmux
    tmux attach -t $session_name

    #cleanup
    unset docker_command
    unset session_name
    unset now_timestamp
}


function prod_web_tmux {
    SSH_BASE_COMMAND="ssh prod-" 
    SERVER_COUNT=12
    EXCLUDE_SERVER="^[8-9]$|^10$"
    DOCKER_USER='admin' 
    DOCKER_FOLDER="/home/admin/html/seven-platform" 
    DOCKER_CONTAINER=nginx_1
    SESSION_BASE='seven_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_workers_tmux {
    SSH_BASE_COMMAND="ssh prod-" 
    SERVER_COUNT=10
    EXCLUDE_SERVER="^[1-7]$"
    DOCKER_USER='admin' 
    DOCKER_FOLDER="/home/admin/html/seven-platform" 
    DOCKER_CONTAINER=nginx_1
    SESSION_BASE='seven_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_rmq_tmux {
    SSH_BASE_COMMAND="ssh prod-rmq-" 
    SERVER_COUNT=5
    EXCLUDE_SERVER="^[1-2]$"
    DOCKER_FOLDER="/" 
    DOCKER_CONTAINER=rmq
    SESSION_BASE='seven_prod_rmq_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}


function prod_tmux {
    SSH_BASE_COMMAND="ssh prod-" 
    SERVER_COUNT=12
    DOCKER_USER='admin' 
    DOCKER_FOLDER="/home/admin/html/seven-platform" 
    DOCKER_CONTAINER=nginx_1
    SESSION_BASE='seven_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_old_tmux {
    SSH_BASE_COMMAND="ssh prod-old-" 
    SERVER_COUNT=5 
    EXCLUDE_SERVER=3
    DOCKER_USER='admin' 
    DOCKER_FOLDER="/home/admin/html/seven-platform" 
    DOCKER_CONTAINER=lighttpd_1
    SESSION_BASE='seven_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_redis_tmux {
    SSH_BASE_COMMAND="ssh prod-redis-" 
    SERVER_COUNT=4 
    EXCLUDE_SERVER=1
    DOCKER_FOLDER="/" 
    DOCKER_CONTAINER=redis
    SESSION_BASE='seven_prod_redis' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_scm_tmux {
    SSH_BASE_COMMAND="ssh prod-cm-" 
    SERVER_COUNT=6 
    DOCKER_USER='ncm-admin' 
    DOCKER_FOLDER="/home/ncm-admin/html/7cm" 
    DOCKER_CONTAINER=nodejs_1
    SESSION_BASE='seven_prod_cm_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}


function prod_db_tmux {
    SSH_BASE_COMMAND="ssh prod-db-" 
    SERVER_COUNT=3 
    DOCKER_FOLDER="/var/lib/mysql" 
    DOCKER_CONTAINER=mariadb
    SESSION_BASE='seven_mariadb' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_report_web_tmux {
    SSH_BASE_COMMAND="ssh prod-reporting-web-"
    SERVER_COUNT=2
    DOCKER_USER='report'
    DOCKER_FOLDER="/home/report/html/seven-reporting"
    DOCKER_CONTAINER=lighttpd_1
    SESSION_BASE='prod_report_web_'
    server_tmuxer "$@"
    server_tmuxer_cleanup
}

function prod_report_worker_tmux {
    SSH_BASE_COMMAND="ssh prod-reporting-worker-"
    SERVER_COUNT=2
    DOCKER_USER='report'
    DOCKER_FOLDER="/home/report/html/seven-reporting"
    DOCKER_CONTAINER=nginx
    SESSION_BASE='prod_report_worker_'
    server_tmuxer "$@"
    server_tmuxer_cleanup
}

function prod_ngs_tmux {
    SSH_BASE_COMMAND="ssh prod-ngs-" 
    SERVER_COUNT=3 
    DOCKER_USER='ngs-admin' 
    DOCKER_FOLDER="/home/ngs-admin/html/nsoft-games-service" 
    DOCKER_CONTAINER=lighttpd_1
    SESSION_BASE='seven_prod_ngs_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_tmux {
    SSH_BASE_COMMAND="ssh staging-" 
    SERVER_COUNT=3 
    DOCKER_USER='admin' 
    DOCKER_FOLDER="/home/admin/html/seven-platform" 
    DOCKER_CONTAINER=nginx_1 
    SESSION_BASE='seven_staging_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_rmq_tmux {
    SSH_BASE_COMMAND="ssh staging-rmq-"
    SERVER_COUNT=6
    EXCLUDE_SERVER="^[1-3]$"
    DOCKER_FOLDER="/"
    DOCKER_CONTAINER=rmq
    SESSION_BASE='seven_staging_rmq_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_scm_tmux {
    SSH_BASE_COMMAND="ssh staging-cm-" 
    SERVER_COUNT=3
    DOCKER_USER='ncm-admin' 
    DOCKER_FOLDER="/home/ncm-admin/html/7cm" 
    DOCKER_CONTAINER=nodejs_1
    SESSION_BASE='seven_staging_cm_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_db_tmux {
    SSH_BASE_COMMAND="ssh staging-db-" 
    SERVER_COUNT=3 
    DOCKER_FOLDER="/var/lib/mysql" 
    DOCKER_CONTAINER=mariadb
    SESSION_BASE='seven_staging_mariadb' 
    echo "TEST";
    echo $DOCKER_USER
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_report_tmux {
    SSH_BASE_COMMAND="ssh staging-report-"
    SERVER_COUNT=1
    DOCKER_USER='report'
    DOCKER_FOLDER="/home/report/html/seven-reporting"
    DOCKER_CONTAINER=lighttpd_1
    SESSION_BASE='seven_staging_report_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function bb_prod_tmux {
    SSH_BASE_COMMAND="ssh bb-prod-" 
    SERVER_COUNT=3 
    DOCKER_USER='admin' 
    DOCKER_FOLDER="/home/admin/html/seven-platform" 
    DOCKER_CONTAINER=nginx_1
    SESSION_BASE='seven_bb_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function bb_prod_all_tmux {
    SSH_BASE_COMMAND="ssh bb-prod-" 
    SERVER_COUNT=12
    DOCKER_USER='admin' 
    DOCKER_FOLDER="/home/admin/html/seven-platform" 
    DOCKER_CONTAINER=nginx_1
    SESSION_BASE='seven_bb_prod_all_' 
    server_tmuxer "$@"
    server_tmuxer_cleanup
}

function bb_prod_workers_tmux {
    SSH_BASE_COMMAND="ssh bb-prod-" 
    SERVER_COUNT=5
    EXCLUDE_SERVER="^[1-3]$"
    DOCKER_USER='admin' 
    DOCKER_FOLDER="/home/admin/html/seven-platform" 
    DOCKER_CONTAINER=nginx_1
    SESSION_BASE='seven_bb_prod_workers_' 
    server_tmuxer "$@"
    server_tmuxer_cleanup
}

function bb_prod_scm_tmux {
    SSH_BASE_COMMAND="ssh bb-prod-cm-" 
    SERVER_COUNT=2 
    DOCKER_USER='ncm-admin' 
    DOCKER_FOLDER="/home/ncm-admin/html/7cm" 
    DOCKER_CONTAINER=nodejs_1
    SESSION_BASE='seven_bb_prod_cm_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function bb_prod_redis_tmux {
    SSH_BASE_COMMAND="ssh bb-prod-redis-" 
    SERVER_COUNT=1 
    DOCKER_FOLDER="/" 
    DOCKER_CONTAINER=redis
    SESSION_BASE='seven_bb_redis_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function bb_prod_db_tmux {
    SSH_BASE_COMMAND="ssh bb-prod-db-" 
    SERVER_COUNT=3 
    DOCKER_FOLDER="/var/lib/mysql" 
    DOCKER_CONTAINER=mariadb
    SESSION_BASE='seven_bb_mariadb' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function bb_prod_rmq_tmux {
    SSH_BASE_COMMAND="ssh bb-prod-rmq-"
    SERVER_COUNT=1
    DOCKER_FOLDER="/"
    DOCKER_CONTAINER=rabbitmq
    SESSION_BASE='seven_bb_prod_rmq_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function rom_prod_tmux {
    SSH_BASE_COMMAND="ssh rom-prod-" 
    SERVER_COUNT=2 
    DOCKER_USER='admin' 
    DOCKER_FOLDER="/home/admin/html/seven-platform" 
    DOCKER_CONTAINER=nginx_1
    SESSION_BASE='seven_rom_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function rom_prod_rmq_tmux {
    SSH_BASE_COMMAND="ssh rom-prod-rmq-"
    SERVER_COUNT=3
    DOCKER_FOLDER="/"
    DOCKER_CONTAINER=rmq
    SESSION_BASE='seven_rom_prod_rmq_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function rom_prod_redis_tmux {
    SSH_BASE_COMMAND="ssh rom-prod-redis-" 
    SERVER_COUNT=1 
    DOCKER_FOLDER="/" 
    DOCKER_CONTAINER=redis
    SESSION_BASE='seven_rom_redis_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function rom_prod_scm_tmux {
    SSH_BASE_COMMAND="ssh rom-prod-cm-" 
    SERVER_COUNT=5 
    DOCKER_USER='ncm-admin' 
    DOCKER_FOLDER="/home/ncm-admin/html/7cm" 
    DOCKER_CONTAINER=nodejs_1
    SESSION_BASE='seven_rom_prod_cm_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function rom_prod_db_tmux {
    SSH_BASE_COMMAND="ssh rom-prod-db-" 
    SERVER_COUNT=3 
    DOCKER_FOLDER="/var/lib/mysql" 
    DOCKER_CONTAINER=mariadb
    SESSION_BASE='seven_rom_mariadb' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function rom2_prod_tmux {
    SSH_BASE_COMMAND="ssh rom2-prod-" 
    SERVER_COUNT=3 
    DOCKER_USER='admin' 
    DOCKER_FOLDER="/home/admin/html/seven-platform" 
    DOCKER_CONTAINER=nginx_1
    SESSION_BASE='seven_rom_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function rom2_prod_web_tmux {
    SSH_BASE_COMMAND="ssh rom2-prod-" 
    SERVER_COUNT=2 
    DOCKER_USER='admin' 
    DOCKER_FOLDER="/home/admin/html/seven-platform" 
    DOCKER_CONTAINER=nginx_1
    SESSION_BASE='seven_rom_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function rom2_prod_rmq_tmux {
    SSH_BASE_COMMAND="ssh rom2-prod-rmq-"
    SERVER_COUNT=3
    DOCKER_FOLDER="/"
    DOCKER_CONTAINER=rmq
    SESSION_BASE='seven_rom_prod_rmq_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function rom2_prod_redis_tmux {
    SSH_BASE_COMMAND="ssh rom2-prod-redis-" 
    SERVER_COUNT=3 
    DOCKER_FOLDER="/" 
    DOCKER_CONTAINER=redis
    SESSION_BASE='seven_rom_redis_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function rom2_prod_scm_tmux {
    SSH_BASE_COMMAND="ssh rom2-prod-cm-" 
    SERVER_COUNT=3 
    DOCKER_USER='ncm-admin' 
    DOCKER_FOLDER="/home/ncm-admin/html/7cm" 
    DOCKER_CONTAINER=nodejs_1
    SESSION_BASE='seven_rom_prod_cm_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function rom2_prod_db_tmux {
    SSH_BASE_COMMAND="ssh rom2-prod-db-" 
    SERVER_COUNT=3 
    DOCKER_FOLDER="/var/lib/mysql" 
    DOCKER_CONTAINER=mariadb
    SESSION_BASE='seven_rom_mariadb' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function dev_tmux {
    SSH_BASE_COMMAND="ssh dev-" 
    SERVER_COUNT=2 
    DOCKER_USER='admin' 
    DOCKER_FOLDER="/home/admin/html/seven-platform" 
    DOCKER_CONTAINER=nginx
    SESSION_BASE='seven_dev_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function dev_scm_tmux {
    SSH_BASE_COMMAND="ssh dev-cm-" 
    SERVER_COUNT=1 
    DOCKER_USER='cm' 
    DOCKER_FOLDER="/home/cm/html/7cm" 
    DOCKER_CONTAINER=nodejs_1
    SESSION_BASE='seven_dev__cm_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tc_tmux {
    SSH_BASE_COMMAND="ssh prod-tc-" 
    SERVER_COUNT=2 
    DOCKER_USER='tc-api' 
    DOCKER_FOLDER="/home/tc-api/html/tc-api" 
    DOCKER_CONTAINER=nginx_1
    SESSION_BASE='seven_tc_prod' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tc_db_tmux {
    SSH_BASE_COMMAND="ssh prod-tc-db-" 
    SERVER_COUNT=3 
    DOCKER_FOLDER="/var/lib/mysql" 
    DOCKER_CONTAINER=mariadb_1
    SESSION_BASE='seven_tc_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_redis_tmux {
    SSH_BASE_COMMAND="ssh staging-redis-" 
    SERVER_COUNT=3 
    DOCKER_FOLDER="/var/log" 
    DOCKER_CONTAINER=redis
    SESSION_BASE='seven_redis_staging_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function dev_accounts_tmux {
    SSH_BASE_COMMAND="ssh dev-" 
    SERVER_COUNT=2 
    DOCKER_USER='accounts' 
    DOCKER_FOLDER="/home/accounts/html/seven-accounts" 
    DOCKER_CONTAINER=nginx
    SESSION_BASE='seven_accounts_dev_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_accounts_tmux {
    SSH_BASE_COMMAND="ssh staging-accounts-" 
    SERVER_COUNT=3 
    DOCKER_USER='accounts' 
    DOCKER_FOLDER="/home/accounts/html/seven-accounts" 
    DOCKER_CONTAINER=nginx
    SESSION_BASE='seven_accounts_staging_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_accounts_tmux {
    SSH_BASE_COMMAND="ssh prod-accounts-" 
    SERVER_COUNT=2 
    DOCKER_USER='accounts' 
    DOCKER_FOLDER="/home/accounts/html/seven-accounts" 
    DOCKER_CONTAINER=nginx
    SESSION_BASE='seven_accounts_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_loyalty_tmux {
    SSH_BASE_COMMAND="ssh staging-loyalty-" 
    SERVER_COUNT=3 
    DOCKER_USER='loyalty' 
    DOCKER_FOLDER="/home/loyalty/html/seven-loyalty" 
    DOCKER_CONTAINER=nginx
    SESSION_BASE='seven_loyalty_staging_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function dev_loyalty_tmux {
    SSH_BASE_COMMAND="ssh dev-" 
    SERVER_COUNT=2 
    DOCKER_USER='loyalty' 
    DOCKER_FOLDER="/home/loyalty/html/seven-loyalty" 
    DOCKER_CONTAINER=nginx
    SESSION_BASE='seven_loyalty_dev_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_loyalty_redis_tmux {
    SSH_BASE_COMMAND="ssh staging-loyalty-" 
    SERVER_COUNT=3 
    DOCKER_FOLDER="/var/log" 
    DOCKER_CONTAINER=" redis" #there is also some sentinel that gives us two results
    SESSION_BASE='seven_loyalty_redis_staging_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_loyalty_db_tmux {
    SSH_BASE_COMMAND="ssh staging-loyalty-" 
    SERVER_COUNT=3 
    DOCKER_FOLDER="/var/lib/mysql" 
    DOCKER_CONTAINER=mariadb
    SESSION_BASE='seven_staging_loyalrty_mariadb_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_loyalty_tmux {
    SSH_BASE_COMMAND="ssh prod-loyalty-" 
    SERVER_COUNT=2 
    DOCKER_USER='loyalty' 
    DOCKER_FOLDER="/home/loyalty/html/seven-loyalty" 
    DOCKER_CONTAINER=nginx
    SESSION_BASE='seven_loyalty_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function dev_tag_tmux {
    SSH_BASE_COMMAND="ssh dev-"
    SERVER_COUNT=2
    DOCKER_USER='tag-admin'
    DOCKER_FOLDER="/home/tag-admin/html/seven-tag"
    DOCKER_CONTAINER=nginx
    SESSION_BASE='seven_tag_dev_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_tag_tmux {
    SSH_BASE_COMMAND="ssh staging-"
    SERVER_COUNT=3
    DOCKER_USER='tag-admin'
    DOCKER_FOLDER="/home/tag-admin/html/seven-tag"
    DOCKER_CONTAINER=nginx
    SESSION_BASE='seven_tag_staging_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tag_tmux {
    SSH_BASE_COMMAND="ssh prod-tag-"
    SERVER_COUNT=4
    DOCKER_FOLDER="/home/seven-tag/html/seven-tag"
    DOCKER_CONTAINER=php-fpm
    SESSION_BASE='seven_tag_prod_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tag_web_tmux {
    SSH_BASE_COMMAND="ssh prod-tag-"
    SERVER_COUNT=4
    EXCLUDE_SERVER="^[3-4]$"
    DOCKER_FOLDER="/home/seven-tag/html/seven-tag"
    DOCKER_CONTAINER=php-fpm
    SESSION_BASE='seven_tag_prod_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tag_workers_tmux {
    SSH_BASE_COMMAND="ssh prod-tag-"
    SERVER_COUNT=4
    EXCLUDE_SERVER="^[1-2]$"
    DOCKER_FOLDER="/home/seven-tag/html/seven-tag"
    DOCKER_CONTAINER=php-fpm
    SESSION_BASE='seven_tag_prod_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tag_db_tmux {
    SSH_BASE_COMMAND="ssh prod-tag-db-" 
    SERVER_COUNT=3
    DOCKER_FOLDER="/var/lib/mysql" 
    DOCKER_CONTAINER=docker_mariadb_1
    SESSION_BASE='seven_tag_mariadb' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tag_redis_tmux {
    SSH_BASE_COMMAND="ssh prod-tag-redis-" 
    SERVER_COUNT=3 
    DOCKER_FOLDER="/var/log" 
    DOCKER_CONTAINER=' redis' 
    SESSION_BASE='seven_tag_redis_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tag_rmq_tmux {
    SSH_BASE_COMMAND="ssh prod-tag-rmq-"
    SERVER_COUNT=3
    DOCKER_FOLDER="/"
    DOCKER_CONTAINER=rmq
    SESSION_BASE='seven_prod_tag_rmq_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function dev_iam_am_tmux {
    SSH_BASE_COMMAND="ssh dev-iam-am-"
    SERVER_COUNT=1
    DOCKER_FOLDER="/home/iam-am/html/seven-iam-am"
    DOCKER_CONTAINER=php-fpm
    SESSION_BASE='seven_iam_am_dev_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_iam_am_tmux {
    SSH_BASE_COMMAND="ssh staging-iam-am-"
    SERVER_COUNT=2
    DOCKER_FOLDER="/home/iam-am/html/seven-iam-am"
    DOCKER_CONTAINER=php-fpm
    SESSION_BASE='seven_iam_am_staging_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_iam_am_tmux {
    SSH_BASE_COMMAND="ssh prod-iam-am-"
    SERVER_COUNT=4
    DOCKER_FOLDER="/home/iam-am/html/seven-iam-am"
    DOCKER_CONTAINER=php-fpm
    SESSION_BASE='seven_iam_am_prod_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_iam_am_web_tmux {
    SSH_BASE_COMMAND="ssh prod-iam-am-" 
    SERVER_COUNT=4
    EXCLUDE_SERVER="^[3-4]$"
    DOCKER_FOLDER="/home/iam-am/html/seven-iam-am"
    DOCKER_CONTAINER=php-fpm
    SESSION_BASE='seven_iam_am_prod_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

alias prod_iam_am_non_workers_tmux="prod_iam_am_web_tmux "

function prod_iam_am_workers_tmux {
    SSH_BASE_COMMAND="ssh prod-iam-am-" 
    SERVER_COUNT=4
    EXCLUDE_SERVER="^[1-2]$"
    DOCKER_FOLDER="/home/iam-am/html/seven-iam-am"
    DOCKER_CONTAINER=php-fpm
    SESSION_BASE='seven_iam_am_prod_'
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_iam_am_db_tmux {
    SSH_BASE_COMMAND="ssh prod-iam-am-db-" 
    SERVER_COUNT=3
    DOCKER_FOLDER="/var/lib/mysql" 
    DOCKER_CONTAINER=mariadb
    SESSION_BASE='seven_iam_am_mariadb' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function staging_tpa_tmux {
    SSH_BASE_COMMAND="ssh staging-tpa-" 
    SERVER_COUNT=3 
    DOCKER_USER='tpa-management' 
    DOCKER_FOLDER="/home/tpa-management/html/tpa-management" 
    DOCKER_CONTAINER=nginx
    SESSION_BASE='seven_tpa_management_staging_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tpa_tmux {
    SSH_BASE_COMMAND="ssh prod-tpa-" 
    SERVER_COUNT=2 
    DOCKER_USER='root' 
    DOCKER_FOLDER="/home/tpa-management/html/tpa-management" 
    DOCKER_CONTAINER=php-fpm
    SESSION_BASE='seven_tpa_management_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tax_fis_tmux {
    SSH_BASE_COMMAND="ssh prod-tax-fis-" 
    SERVER_COUNT=2 
    DOCKER_USER='root' 
    DOCKER_FOLDER="/home/seven-tax-superbet/superbet-fiscalization" 
    DOCKER_CONTAINER=java
    SESSION_BASE='superbet_fis_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tax_mne_tmux {
    SSH_BASE_COMMAND="ssh prod-tax-mne-" 
    SERVER_COUNT=2 
    DOCKER_USER='tax-admin' 
    DOCKER_FOLDER="/home/tax-admin/html/seven-tax-authority-mne" 
    DOCKER_CONTAINER=nginx
    SESSION_BASE='mne_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tax_bih_tmux {
    SSH_BASE_COMMAND="ssh prod-tax-bih-central-" 
    SERVER_COUNT=2 
    DOCKER_USER='root' 
    DOCKER_FOLDER="/home/tax-admin/html/seven-tax-authority-bih-fbih" 
    DOCKER_CONTAINER=php-fpm
    SESSION_BASE='fbih_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

function prod_tax_rom_tmux {
    SSH_BASE_COMMAND="ssh prod-tax-rom-" 
    SERVER_COUNT=2 
    DOCKER_USER='tax-admin' 
    DOCKER_FOLDER="/home/tax-admin/html/seven-tax-authority-rom" 
    DOCKER_CONTAINER=nginx
    SESSION_BASE='rom_prod_' 
    server_tmuxer $@
    server_tmuxer_cleanup
}

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/ahalac/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/home/ahalac/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/ahalac/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/ahalac/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
alias k=kubectl
complete -F __start_kubectl k

source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

