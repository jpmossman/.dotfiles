#!/bin/sh
main() {
  SHARED_STOW_OPTS="--no-folding --adopt -t $HOME -d stows"
  stow $SHARED_STOW_OPTS git
  stow $SHARED_STOW_OPTS bash
  stow $SHARED_STOW_OPTS zsh
  stow $SHARED_STOW_OPTS nvim
  stow $SHARED_STOW_OPTS wezterm
  stow $SHARED_STOW_OPTS oh-my-posh
}
main
