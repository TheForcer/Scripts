#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Color for ls and grep/ egrep
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'

# Nicer font colors
PS1='${debian_chroot:+($debian_chroot)}[\033[01;31m]\u[\033[01;33m]@[\033[01;36m]\h [\033[01;33m]\w [\033[01;35m]$ [\033[00m]'

# Prevent accidentally removing of files
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Human-readable df output by default
alias df='df -kTh'

# Docker-compose shortcuts
alias dup='docker-compose up'
alias ddown='docker-compose down'

# Fix stupid docker CLI design
docker() {
    if [[ $@ == "containers" ]]; then
        command docker container ls
    elif [[ $@ == "volumes" ]]; then
        command docker volume ls
    elif [[ $@ == "reset" ]]; then
        read -p "Do you really want to completely reset docker (remove all images, containers and volumes) [Y/n]? " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            command docker system prune -af && command docker volume prune -f  
        fi   
    else
        command docker "$@"
    fi
}
