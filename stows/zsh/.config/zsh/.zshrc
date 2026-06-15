# dotfile directory for zsh
export ZDOTDIR="$HOME/.config/zsh"
# TODO: Find autocomplete alternative to oh-my-zsh
# export ZSH="$HOME/.cache/oh-my-zsh"
export ZSH=$ZDOTDIR/ohmyzsh
source $ZDOTDIR/ohmyzsh/oh-my-zsh.sh
# history settings
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=1000
SAVEHIST=1000
setopt appendhistory

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='code'
# fi
export EDITOR="nvim"

# Add stuff to path
export "PATH=$PATH:$HOME/.local/bin"
if [ `uname` = "Darwin" ] ; then
  if [ `uname -m` = "arm64" ] ; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  if [ `uname -m` = "x86_64" ] ; then
    eval "$(/usr/local/homebrew/bin/brew shellenv)"
  fi
fi
if [ `uname` = "Linux" ] ;  then
  export "PATH=$PATH:/home/linuxbrew/.linuxbrew/bin"
fi
export PATH="$PATH:$HOME/scripts"
export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:$HOME/Desktop/MyApplications/Cursor.app/Contents/MacOS"
export PATH="$PATH:$HOME/Desktop/MyApplications/Ollama.app/Contents/MacOS"
export PATH="$PATH:$HOME/scripts/arm-gnu-toolchain/arm-gnu-toolchain-15.2.rel1-darwin-arm64-arm-none-eabi/bin"
# export PAHT="$PATH:$HOME/Desktop/MyApplications/Ollama.app/Contents/MacOS/"

# function path_append() {
#   export PATH="$PATH:$1"
# }
# path_append "$HOME/scripts/arm-gnu-toolchain/arm-gnu-toolchain-15.2.rel1-darwin-arm64-arm-none-eabi/bin"

. "$HOME/.cargo/env"

# Add personal aliases
alias dmenu='rofi -dmenu'
alias python=python3
alias ls="lsd"
alias la="ls -lAh"
alias ll="ls -l"
alias lla="ls -lah"
alias cat="bat --paging=never"
alias lTree="exa --icons -T --git-ignore -I .git"
if [ `uname` = "Darwin" ] ; then
  alias imgcat="wezterm imgcat"
fi
alias timestamp="date +%y%m%d_%H%M%S"

# Use beam instead of block cursor
echo -ne '\e[5 q'

# Remove less history file
export LESSHISTFILE="$XDG_STATE_HOME"/less/history

# Start zsh in a zellij session
# eval "$(zellij setup --generate-auto-start zsh)"

# Set prompt engine
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/julia.yaml)"
# export STARSHIP_CONFIG=~/.config/starship/julia.toml
# eval "$(starship init zsh)"

# Set default docker architecture
export DOCKER_DEFAULT_PLATFORM=linux/amd64

# Auto completions
_uuu_autocomplete()
{
  COMPREPLY=($(/opt/homebrew/Cellar/uuu/1.5.182/bin/uuu $1 $2 $3))
}
complete -o nospace -F _uuu_autocomplete  uuu

export BARTIB_FILE="$HOME/notes/bartib.txt"

check_uptime() {
  local BOOTTIME=$(sysctl -n kern.boottime | awk '{print $4}' | sed 's/,//g')
  local NOW=$(date +%s)
  local DIFF=$((NOW - BOOTTIME))
  local DIFF_S=$((DIFF % 60))
  local DIFF_M=$((DIFF / 60 % 60))
  local DIFF_H=$((DIFF / 3600 % 24))
  local DIFF_D=$((DIFF / 86400))
  local MAX_DAYS=3
  local MAX_S=$((3*24*60*60))
  echo "Uptime: ${DIFF_D}d ${DIFF_H}h ${DIFF_M}m ${DIFF_S}s (${DIFF}s total)"
  if (( DIFF > MAX_S )); then
    echo "System uptime is greater than ${MAX_DAYS} days, please reboot or I'll die"
  fi
}
check_uptime
export PATH="$HOMEBREW_PREFIX/opt/uutils-coreutils/libexec/uubin:$PATH"

_bartib_completions()
{
	local CWORD=${COMP_WORDS[COMP_CWORD]}
	ALL_PROJECTS=`bartib projects`

	local IFS=$'\n'
	CANDIATE_PROJECTS=($(compgen -W "${ALL_PROJECTS[*]}" -- "$CWORD"))

	if [ ${#CANDIATE_PROJECTS[*]} -eq 0 ]; then
		COMPREPLY=()
	else
		COMPREPLY=($(printf "\"%s\"\n" "${CANDIATE_PROJECTS[@]}"))
	fi
}

complete -F _bartib_completions bartib
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

alias source_creds="source ~/.dotfiles/creds.env"

source "$HOME/.zshenv"

source "$HOME/scripts/shell-logger.zsh"
