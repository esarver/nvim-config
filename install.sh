#!/usr/bin/env bash

print_help() {
    cat << EOF
 USAGE: $0 USER GROUP
    USER:    The user that should own any newly created directories
    GROUP:    The group that should own any newly created directories

    INSTALLATION NOTES:
       This script will run several steps using sudo.

       This script will install the follow items from source:
          - Neovim: /opt/neovim (built into /opt/neovim/release with symlink
                    in /usr/local/bin)

       This script will also install many other pieces of software using npm,
       pip and the native package manager.
EOF
}

if [[ $# -ne 2 ]]; then
    print_help
    exit 1
fi

USER="$1"
GROUP="$2"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
install "$SCRIPT_DIR/init.vim" -D --target-directory="$HOME/.config/nvim"

install_nvim() {
    sudo mkdir /opt/neovim
    sudo chown "$USER:$GROUP" /opt/neovim
    git clone https://github.com/neovim/neovim.git /opt/neovim
    mkdir -p /opt/neovim/release
    (cd /opt/neovim \
        && make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX=/opt/neovim/release install)
    sudo ln -sf /opt/neovim/release/bin/nvim /usr/local/bin/
}

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
            clang-tools-extra \
	    ninja-build \
	    libtool \
	    autoconf \
	    automake \
	    cmake \
	    gcc \
	    gcc-c++ \
	    make \
	    pkgconfig \
	    unzip \
	    patch \
	    gettext \
	    ShellCheck \
	    curl
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

lualsp_install() {
    echo "Installing lua-lsp..."
    sudo mkdir -p /opt/lua-lsp
    sudo chown "$USER:$GROUP" /opt/lua-lsp
    (cd /opt/lua-lsp \
        && curl -L https://github.com/sumneko/lua-language-server/releases/download/2.5.6/lua-language-server-2.5.6-linux-x64.tar.gz | tar xzf - \
        && sudo ln -sf /opt/lua-lsp/bin/lua-language-server /usr/local/bin/lua-language-server \
    )
    echo "Installation of lua-lsp complete!"
}

native_packages \
    && install_nvim \
    && npm_install \
    && install_plug \
    && pip_install \
    && rust_install \
    && lualsp_install
