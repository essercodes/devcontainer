#!/bin/bash
set -e

# Provides 'check' and 'reportResults'.
source dev-container-features-test-lib

# Every feature installed side by side on one image. The per-feature tests each
# run in isolation, so this is the only place a conflict between them (a
# clobbered rc file, a stolen /usr/local/bin symlink) would show up.
#
# neovim-config is deliberately excluded: it pulls in rust/node/python and
# compiles tree-sitter-cli, which turns a 2 minute job into a 15 minute one.

REMOTE_USER="ubuntu"
if [ "$(id -un)" = "$REMOTE_USER" ]; then
  AS_USER="bash -lc"
else
  AS_USER="su - $REMOTE_USER -c"
fi

check "nvim starts" bash -c "nvim --headless +qa"
check "fzf starts" bash -c "fzf --version"
check "tmux starts" bash -c "tmux -V"

# claudecode and opencode install into the remote user's home and rely on their
# rc files for PATH, hence the login shell.
# shellcheck disable=SC2086
check "opencode starts" $AS_USER "opencode --version"
# shellcheck disable=SC2086
check "claude starts" $AS_USER "claude --version"

# Several installers append to the same rc file. If one overwrote another's
# block only that tool's check would fail, so assert the fzf block survived.
check "fzf shell integration survived the other features" \
  bash -c "grep -q 'fzf --bash' /home/$REMOTE_USER/.bashrc"

reportResults
