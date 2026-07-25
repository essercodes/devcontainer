#!/bin/sh
set -eu

echo "Activating feature 'Neovim Config'"

NVIM_CONFIG_URL="${CONFIGURL:-https://github.com/essercodes/neovim-config}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: this script must run as root." >&2
  exit 1
fi

# The feature 'username' option wins. 
# Otherwise use _REMOTE_USER / _REMOTE_USER_HOME, 
# falls back to _CONTAINER_USER when remoteUser is unset.

USERNAME="${USERNAME:-automatic}"
if [ "$USERNAME" = "automatic" ] || [ "$USERNAME" = "" ]; then
  USERNAME="${_REMOTE_USER:-}"
  USER_HOME="${_REMOTE_USER_HOME:-}"

  if [ -z "$USERNAME" ]; then
    echo "Error: _REMOTE_USER is unset. Run this via the devcontainer CLI, or" >&2
    echo "pass the 'username' option explicitly." >&2
    exit 1
  fi

else
  USER_HOME=""
fi

if ! id -u "$USERNAME" >/dev/null 2>&1; then
  echo "Error: user '${USERNAME}' does not exist in this image." >&2
  exit 1
fi

# Explicit username, or a CLI that did not supply the home directory.
if [ -z "$USER_HOME" ]; then
  USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"
fi

echo "Installing for user '${USERNAME}' (home: ${USER_HOME})"
if [ "$USERNAME" = "root" ]; then
  echo "Warning: resolved to root, so the config will go to ${USER_HOME} and" >&2
  echo "will not be visible to a non-root user. Set \"remoteUser\" in" >&2
  echo "devcontainer.json, or pass the 'username' option." >&2
fi

NVIM_CONFIG_DIR="${USER_HOME}/.config/nvim"

# -H sets HOME to the target user's home. Without it sudo leaves HOME pointing
# at /root, and Lazy/Mason would install everything into /root/.local/share.
as_user() {
  sudo -u "$USERNAME" -H "$@"
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
as_user mkdir -p "${USER_HOME}/.config"
as_user git clone --depth 1 "$NVIM_CONFIG_URL" "$NVIM_CONFIG_DIR"

echo "## Install Neovim plugins and tools ##"
as_user nvim --headless \
    "+Lazy! sync" \
    +qa

as_user nvim \
    -c 'autocmd User MasonToolsUpdateCompleted quitall' \
    -c 'MasonToolsInstall' \
    +qa

echo "Done. Config installed to ${NVIM_CONFIG_DIR} for user ${USERNAME}."
