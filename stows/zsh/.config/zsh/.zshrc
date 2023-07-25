# dotfile directory for zsh
export ZDOTDIR="$HOME/.config/zsh"

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
export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin
eval "$(/opt/homebrew/bin/brew shellenv)"
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

# Use beam instead of block cursor
echo -ne '\e[5 q'

# Remove less history file
export LESSHISTFILE="$XDG_STATE_HOME"/less/history

# Start zsh in a zellij session
eval "$(zellij setup --generate-auto-start zsh)"

# Set prompt engine
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/julia.yaml)"
# export STARSHIP_CONFIG=~/.config/starship/julia.toml
# eval "$(starship init zsh)"