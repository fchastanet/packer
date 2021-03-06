#!/bin/bash

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias folder-size='sudo du -hs -c *'
alias folder-size-sorter="sudo find . -maxdepth 1 -exec sudo du -hs '{}' ';' | sort -h"
alias ps_full_command='ps -efww'

# applications shortcuts
alias code='/usr/bin/code >/dev/null 2>&1'
alias docker-compose-down-one-service='docker-compose rm -f -s'

# git commands
gitSafelyRemoveLocalBranch() {
    local branch="$1"
    git tag "${branch}" "${branch}" && git branch -D "${branch}"
}
alias git-safely-remove-local-branch='gitSafelyRemoveLocalBranch'

gitListBranchesForCommit() {
    local branch="$1"
    git branch -a --contains "${branch}"
}
alias git-list-branches-for-commit='gitListBranchesForCommit'

UI::askYesNo() {
    while true; do
        read -p "$1 (y or n)? " -n 1 -r
        echo    # move to a new line
        case ${REPLY} in
            [yY]) return 0;;
            [nN]) return 1;;
            *)
                read -N 10000000 -t '0.01' ||true; # empty stdin in case of control characters
                # \\r to go back to the beginning of the line
                Log::displayError "\\r invalid answer                                                          "
        esac
    done
}

# undo last pushed commit
# - step 1: remove commit locally
# - step 2: force-push the new HEAD commit
# !!!! use it with care
# this will create an "alternate reality" for people who have already fetch/pulled/cloned from the remote repository.
undoLastPushedCommit() {
    echo -e '\e[33m!!! use it with care\e[0m'
    echo -e '\e[33mthis will create an "alternate reality" for people who have already fetch/pulled/cloned from the remote repository.\e[0m'
    UI::askYesNo "do you confirm" && {
        git reset HEAD^ && git push origin +HEAD
    }
}
alias gitUndoLastPushedCommit='undoLastPushedCommit'

sshKillAllTunnel() {
    if [[ "$(uname -o)" = "Msys" ]]; then
      # git bash: no way to get full process command, just kill all ssh processes
      ps aux | grep '/usr/bin/ssh'  | grep -v 'grep ' | awk -F " " '{print $1}' | xargs -t --no-run-if-empty kill
    else
      ps aux | grep 'ssh.*-L' | grep -v 'grep ' | awk -F " " '{print $2}' | xargs -t --no-run-if-empty kill
    fi
}
alias ssh_kill_all_tunnel='sshKillAllTunnel'

alias restart-VBoxClient="killall VBoxClient && VBoxClient-all"
