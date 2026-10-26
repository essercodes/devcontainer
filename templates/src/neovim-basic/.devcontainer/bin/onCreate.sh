#!/usr/bin/env bash

set -euo pipefail

cat "$CONTAINER_WORKSPACE_FOLDER/.devcontainer/bin/set_shortcuts.sh" >> /home/$REMOTE_USER/.bashrc


BIN_DIR="/usr/local/sbin"
cp  "$CONTAINER_WORKSPACE_FOLDER/.devcontainer/bin/as_non_admin.sh" "$BIN_DIR"
cp  "$CONTAINER_WORKSPACE_FOLDER/.devcontainer/bin/op_env_run.sh" "$BIN_DIR"
cp  "$CONTAINER_WORKSPACE_FOLDER/.devcontainer/bin/claude_ide.sh" "$BIN_DIR"

chown root:root "$BIN_DIR/as_non_admin.sh"
chown root:root "$BIN_DIR/op_env_run.sh"
chown root:root "$BIN_DIR/claude_ide.sh"
chmod 0555 "$BIN_DIR/as_non_admin.sh"
chmod 0555 "$BIN_DIR/op_env_run.sh"
chmod 0555 "$BIN_DIR/claude_ide.sh"

global_git_ignore_url=${GLOBAL_GIT_IGNORE_URL:-"https://raw.githubusercontent.com/essercodes/dotfiles/refs/heads/main/global-gitignore"}
global_git_ignore_path="/home/$REMOTE_USER/.global-gitignore" 
sudo -u "$REMOTE_USER" -- curl -o "$global_git_ignore_path" "$global_git_ignore_url"
sudo -u "$REMOTE_USER" -- git config --global core.excludesfile "$global_git_ignore_path"
