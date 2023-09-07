#!/bin/sh
###############################################################################
# author: JP Mossman
# install script for new systems
###############################################################################
main() {
    install_manual
    install_packages
    stow_packages
}

###############################################################################
# install local dotfiles
###############################################################################
stow_packages() {
    ./stow_all.sh
}

###############################################################################
# Manually install software not handled by package managers
###############################################################################
install_manual() {
    # Define install functions
    install_man_brew() {
        # TODO: Install correct version for OS
        if ! which brew ; then
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # TODO: This next line should not be necessary, just in .zshrc
            echo "export PATH=/home/linuxbrew/.linuxbrew/bin:$PATH" >> ~/.bashrc
        fi
    }
    install_man_rust() {
        if ! which rustup ; then
            curl https://sh.rustup.rs -sSf | sh -s -- -q -y
            # TODO: This next line should not be necessary, just in .zshrc
            echo ". $HOME/.cargo/env" >> ~/.bashrc
        fi
    }
    # Install software
    install_man_brew
    install_man_rust
}

###############################################################################
# Install software with package managers
###############################################################################
install_packages() {
    install_pack_brew() {
        brew update
        brew install jandedobbeleer/oh-my-posh/oh-my-posh
        brew install stow
        brew install neofetch
        brew install onefetch
        brew install zellij
        brew install ripgrep

        # Docker on Mac
        if is_mac ; then
            brew install colima
            brew install docker docker-compose
            # TODO: Link docker-compose to be used as a plugin for docker
        fi

        # Add fonts
        brew tap homebrew/cask-fonts
        brew install --cask font-hack-nerd-font
        brew install --cask font-jetbrains-mono-nerd-font
    }
    install_pack_apt() {
        sudo apt update
        # sudo apt install -y zsh
        echo "no apt packages"
    }
    install_pack_cargo() {
        . $HOME/.cargo/env
        cargo install cargo-binstall
        cargo binstall -y sccache
        cargo binstall -y bat
        cargo binstall -y exa
        cargo binstall -y fd-find
        cargo binstall -y sd
        cargo binstall -y lsd
        cargo binstall -y bob-nvim
        bob use "0.9.1"
    }
    install_pack_brew
    install_pack_apt
    install_pack_cargo
}

###############################################################################
# Helper functions
###############################################################################
# TODO: Verify that these work as intended
is_mac () {
    return false
    # return `uname` = "Darwin"
}

is_linux() {
    return true
    # return `uname` = "Linux"
}

is_wsl() {
    return true
    # return `uname` = "WSL"
}


###############################################################################
# main
###############################################################################
main
