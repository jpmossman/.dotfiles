#!/bin/sh
###############################################################################
# author: JP Mossman
# install script for new systems
###############################################################################
main() {
    install_manual
    install_packages
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
        if ! brew --version ; then
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            echo "export PATH=/home/linuxbrew/.linuxbrew/bin:$PATH" >> ~/.bashrc
        fi
    }
    install_man_rust() {
        if ! rustup --version ; then
            curl https://sh.rustup.rs -sSf | sh -s -- -q -y
            echo ". $HOME/.cargo/env" >> ~/.bashrc
        fi
    }
    install_man_ohmyzsh() {
        if ! [ -d ~/.cache/oh-my-zsh ] ; then
            sudo apt install -y zsh
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            mv $HOME/.zshrc.pre-oh-my-zsh $HOME/.zshrc
        fi
    }
    install_man_ohmyposh() {
        if ! /usr/local/bin/oh-my-posh --version ; then
            sudo apt install -y wget
            sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
        sudo chmod +x /usr/local/bin/oh-my-posh
        fi
    }
    # Install software
    install_man_brew
    install_man_ohmyposh
    install_man_ohmyzsh
    install_man_rust
}

###############################################################################
# Install software with package managers
###############################################################################
install_packages() {
    install_pack_brew() {
        brew update
        # brew install jandedobbeleer/oh-my-posh/oh-my-posh
        brew install stow
    }
    install_pack_apt() {
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
    stow_packages
}

###############################################################################
# main
###############################################################################
main
