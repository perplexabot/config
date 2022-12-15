#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# enable git prompt
source /usr/share/git/git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM="auto"

# PS1 prompt setup
PS1='\[\e]0;\w\a\]\n\[\e[32m\]\u@\h: \[\e[33m\]\w\[\e[0m\] $(__git_ps1 " (%s)") $(kube_ps1)\n\$ '

TODO_FILE="$HOME/.todo"
touch "${TODO_FILE}"

# Mod path
export GOPATH=~/.go/
export PATH=$PATH:$GOPATH/bin

alias ls='ls --color=always'
alias grep='grep --color=always'
alias vim='nvim'
# alias python='python3.6'

export HISTTIMEFORMAT="%d/%m/%y %T "
export HISTSIZE=1000
export HISTFILESIZE=2000

# auto-completes
source /usr/share/bash-completion/completions/git
source <(kubectl completion bash)

# kubectl prompt thing
source '/opt/kube-ps1/kube-ps1.sh'

# aka docker kill
dk () {
    # if a container id was passed kill it
    if [ $# -eq 1 ]; then
        docker kill "$1"
        return 0
    fi

    if [ -n "$CONTAINER_TO_KILL" ]; then
        docker kill "$CONTAINER_TO_KILL"
        return 0
    fi

    # if command was run alone and a single container exists, kill it
    containers=$(docker ps -q)
    if [ "$(echo "$containers" | wc -w)" -eq 0 ]; then
        echo "Nothing to remove"
    elif [ "$(echo "$containers" | wc -w)" -eq 1 ]; then
        docker kill "$containers"
    else
        echo "More than one container exists"
    fi
}

# force delete button to work (this issue arises with st term emulator)
tput smkx

mdView () {
    pandoc "$1" | lynx -stdin
}


# bash functions
openNotebook () {
    local mountPath=/home/${USER}/notebooks
    mkdir -p "${mountPath}"

    docker run -it -p 8888:8888 -v "${mountPath}:/mnt" perplexabot/perplexed-images:jupyter-notebook /bin/bash -c \
            "/opt/conda/bin/conda install jupyter -y --quiet && mkdir \\
            /opt/notebooks && /opt/conda/bin/jupyter notebook \\
            --notebook-dir=/opt/notebooks --ip='*' --port=8888 \\
            --no-browser --allow-root"
}

penv () {
    local PY_VERSION="${PY_VERSION:-3.10}"
    local DEFAULT_LOCATION="/var/tmp/quick-py-env_${PY_VERSION}"
    mkdir -p "${DEFAULT_LOCATION}"

    if [[ "$1" =~ "-n" ]]; then
        deactivate &>/dev/null
        rm -rf "${DEFAULT_LOCATION}"
        echo "PY_VERSION: ${PY_VERSION} - DEFAULT_LOCATION: ${DEFAULT_LOCATION}"
        python -m virtualenv "${DEFAULT_LOCATION}" -p "${PY_VERSION}"
    fi

    source "${DEFAULT_LOCATION}/bin/activate"
}

vimnp () {
    vim --noplugins $@
}

awsDockerLogin () {
    local cmd
    cmd=$(aws ecr get-login --region us-east-1 --no-include-email)
    eval $cmd
}

gitm () {
    GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa_mygit" git $@
}

tagCode () {
    if [ $# -ne 1 ]; then
        echo '[!] Missing extension! Usage: tagCode <extension>'
    else
        ctags -f .tags --recurse=yes --exclude=.git
        cscope -bq $(find . -iname "*.$1" -not -path "*/.venv/*" -not -path "*/.git/*")
    fi
}

cl () {
	local dir="$1"
	local dir="${dir:=$HOME}"
	if [[ -d "$dir" ]]; then
		cd "$dir" >/dev/null; ls
	else
		echo "bash: cl: $dir: Directory not found"
	fi
}

todo() {
    if [[ ! -f $HOME/.todo ]]; then
        touch "${TODO_FILE}"
    fi

    if ! (($#)); then
        cat "$TODO_FILE"
    elif [[ "$1" == "-l" ]]; then
        nl -b a "$TODO_FILE"
    elif [[ "$1" == "-c" ]]; then
        > $HOME/.todo
    elif [[ "$1" == "-r" ]]; then
        nl -b a "$TODO_FILE"
        eval printf %.0s- '{1..'"${COLUMNS:-$(tput cols)}"\}; echo
        read -p "Type a number to remove: " number
        sed -i ${number}d "$TODO_FILE"
    else
        printf "%s\n" "$*" >> "$TODO_FILE"
    fi
}

ipif() {
    if grep -P "(([1-9]\d{0,2})\.){3}(?2)" <<< "$1"; then
	 curl ipinfo.io/"$1"
    else
	ipawk=($(host "$1" | awk '/address/ { print $NF }'))
	curl ipinfo.io/${ipawk[1]}
    fi
    echo
}

serveThis () {
    python -m http.server "${1-8000}" --bind "${2:-127.0.0.1}"
}

dupTerm() {
    i3-sensible-terminal -e "cd $PWD; bash" &>/dev/null &
}

cd () {
    builtin cd "$@" || return 1
    echo "$PWD" > ~/.last_dir
}

terminal_banner () {
    GOALS=("2 Reviews a day" "1 PR a day")
    echo " +++++++++++++++++++++++++++"
    for i in "${GOALS[@]}"; do echo "    [G] ${i}"; done
    echo " +++++++++++++++++++++++++++"
    while read -r line; do
        echo "    [T] $line";
    done < "${TODO_FILE}"
}

terminal_banner
