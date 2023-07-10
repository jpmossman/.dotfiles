#!/bin/sh
main() {
  stow --no-folding git
  stow --no-folding bash
  stow --no-folding zsh
  stow --no-folding nvim
  stow --no-folding wezterm
}
main

