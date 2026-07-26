#!/bin/sh
set -eu

echo "Activating feature 'Neovim Config'"

NVIM_CONFIG_URL="${CONFIGURL:-https://github.com/essercodes/neovim-config}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: this script must run as root." >&2
  exit 1
fi

NVIM_CONFIG_DIR="${_REMOTE_USER_HOME}/.config/nvim"

as_user() {
  sudo -u "$_REMOTE_USER" -H env "PATH=$PATH" "$@"
}

echo "## Install Treesitter dependencies ##"
rm -rf /var/lib/apt/lists/*
apt-get update -y
apt-get install -y clang git sudo
rm -rf /var/lib/apt/lists/*

if ! command -v cargo >/dev/null 2>&1; then
  echo "Error: cargo not found. Add a Rust Feature to this Feature's" >&2
  echo "installsAfter, or drop tree-sitter-cli if the config does not need it." >&2
  exit 1
fi

echo "## Install tree-sitter CLI ##"
cargo install --locked --root /usr/local tree-sitter-cli

echo "## Clone config ##"
as_user mkdir -p "${_REMOTE_USER_HOME}/.config"
as_user git clone --depth 1 "$NVIM_CONFIG_URL" "$NVIM_CONFIG_DIR"

echo "## Install Neovim plugins ##"
as_user nvim --headless "+Lazy! sync" +qa

echo "## Install LSP Servers + Tools ##"
as_user nvim --headless "+Lazy! load mason.nvim" "+MasonInstallAll" +qa

echo "Done. Config installed to ${NVIM_CONFIG_DIR} for user ${_REMOTE_USER}."
