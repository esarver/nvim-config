#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
install "$SCRIPT_DIR/init.vim" -D --target-directory="$HOME/.config/nvim"

install_plug() {
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
}

native_packages() {
    if dnf --version &> /dev/null; then
        echo "Installing native packages using dnf..."
        sudo dnf install -y \
            gzip \
            nodejs \
            npm \
            python3 \
            python3-pip \
            clang-tools-extra
        echo "Installation of native packages complete!"
    elif apt-get --version &> /dev/null; then
        echo "apt not yet supported"
    elif pacman --version &> /dev/null; then
        echo "pacman not yet supported"
    fi
}

pip_install(){
    echo "Installing pip packages..."
    python3 -m pip install --user \
        neovim \
        pyright \
        cmake-language-server
    echo "Installation of pip packages complete!"
}

npm_install(){
    echo "Installing npm packages..."
    sudo npm install -g \
        neovim \
        bash-language-server \
        dockerfile-language-server-nodejs \
        typescript-language-server \
        vim-language-server 
    echo "Installation of npm packages complete!"
}

rust_install(){
    echo "Installing rust packages..."
    if ! rustup --version; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly --profile default
        source "$HOME/.cargo/env"
    fi
    rustup component add rust-src
    mkdir -p ~/.local/bin
    curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > ~/.local/bin/rust-analyzer
    chmod +x ~/.local/bin/rust-analyzer
    echo "Installation of rust packages complete!"
}

native_packages
npm_install
install_plug
pip_install
rust_install
