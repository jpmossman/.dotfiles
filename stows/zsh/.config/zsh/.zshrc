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
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Add stuff to path
export PATH=$PATH:~/.local/bin
if [ `uname` = "Darwin" ] ; then
  if [ `uname -m` = "arm64" ] ; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  if [ `uname -m` = "x86_64" ] ; then
    eval "$(/usr/local/homebrew/bin/brew shellenv)"
  fi
fi
if [ `uname` = "Linux" ] ;  then
  export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin
fi
export PATH=$PATH:~/scripts
export PATH=$PATH:~/.local/share/bob/nvim-bin
. "$HOME/.cargo/env"

# Add personal aliases
alias dmenu='rofi -dmenu'
alias python=python3
alias ls="lsd"
alias la="ls -lAh"
alias ll="ls -l"
alias lla="ls -lah"
alias cat="bat"
alias lTree="exa --icons -T --git-ignore -I .git"
if [ `uname` = "Darwin" ] ; then
  alias wezterm="~/Desktop/MyApplications/WezTerm.app/Contents/MacOS/wezterm"
  alias imgcat="wezterm imgcat"
  alias orb="~/Desktop/MyApplications/Orbstack.app/Contents/MacOS/bin/orb"
  alias orbctl="~/Desktop/MyApplications/Orbstack.app/Contents/MacOS/bin/orbctl"
fi

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
