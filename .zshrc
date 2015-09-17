export COMPLETION_WAITING_DOTS=false
setopt histignorealldups sharehistory
setopt HIST_IGNORE_ALL_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_NO_FUNCTIONS
setopt promptsubst
zstyle ':completion::complete:*' use-cache 1
# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'


#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...

zstyle ':prezto:module:editor' dot-expansion 'no'

#export ZSH=/home/ale/.vincentbernat-zshrc    
#source $ZSH/rc/bookmarks.zsh
source ~/.comune

REPORTTIME=60

if [ -r $HOME/.ssh/known_hosts ]; then
        local _myhosts
        _myhosts=( ${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[0-9]*}%%\ *}%%,*} )
        zstyle ':completion:*' hosts $_myhosts
fi

source ~/.zsh/plugins/nice-exit-code/nice-exit-code.plugin.zsh

function preexec() {
	timer=${timer:-$SECONDS}
}

function precmd() {
  eval "$PROMPT_COMMAND"
  if [ $timer ]; then
    timer_show=$(($SECONDS - $timer))
	pretty=`~/.zsh/plugins/pretty-time-zsh/pretty-time.zsh $timer_show`
        codice='$(nice_exit_code) '
	export RPROMPT="${codice}%F{cyan}${pretty} %{$reset_color%}"
	if [ "$timer_show" -gt "120" ]; then 
		eval "beep"; 
	fi
    unset timer
  fi
}

export TMOUT=3
zmodload zsh/datetime
TRAPALRM() {
#  if (( ! $+commands[cmatrix]  )); then
#    cmatrix -s
#  fi
}

#zle-line-init() {
#    zle autosuggest-start
#}
#zle -N zle-line-init
#bindkey '^f' vi-forward-word
#bindkey '^T' autosuggest-toggle

eval  `dircolors ~/.dir_colors` 

source ~/.zsh/plugins/zsh-bd/bd.zsh
source ~/.zsh/plugins/k/k.plugin.zsh
alias k='k -A -h --no-vcs'
source ~/.zsh/plugins/deer/deer
zle -N deer-launch
bindkey '\ek' deer-launch
source ~/.zsh/plugins/sysadmin-util/sysadmin-util.plugin.zsh
source ~/.zsh/plugins/zsh-directory-history/directory-history.plugin.zsh
source ~/.prompt
export LP_PS1_POSTFIX=$MIOPROMPT
source ~/.zsh/plugins/zsh-dwim/zsh-dwim.plugin.zsh

 # Bind up/down arrow keys to navigate through your history
# bindkey '\e[A' directory-history-search-backward
# bindkey '\e[B' directory-history-search-forward
zmodload zsh/terminfo
 bindkey "$terminfo[kcud1]" directory-history-search-backward
 bindkey "$terminfo[kcuu1]" directory-history-search-forward

 # Bind CTRL+k and CTRL+j to substring search
 bindkey '^j' history-substring-search-up
 bindkey '^k' history-substring-search-down

export LP_PS1_PREFIX="%h "
[[ $- = *i* ]] && source ~/.zsh/plugins/liquidprompt/liquidprompt

#bindkey -rM "$keymap" "$key_info[Control]I"
