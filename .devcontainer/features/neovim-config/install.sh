#!/bin/sh
set -eu
echo "Activating feature 'Neovim Config'"

CONTAINER_USER='ubuntu'
AS_USER="sudo -u $CONTAINER_USER"
NVIM_CONFIG_URL='https://github.com/essercodes/neovim-config'
NVIM_CONFIG_DIR="/home/$CONTAINER_USER/.config/nvim"

echo "## Install Treesitter Dependencies ##"
apt-get -y update
apt-get install -y clang
cargo install --locked tree-sitter-cli

echo "## Clone Config ##"
$AS_USER git clone $NVIM_CONFIG_URL $NVIM_CONFIG_DIR

echo "## Install Neovim Plugins and Tools ##"
$AS_USER nvim --headless -c 'Lazy! sync' +qa
$AS_USER nvim --headless -c 'MasonToolsInstallSync' +qa
