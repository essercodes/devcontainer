#!/bin/bash
set -e

# Provides 'check' and 'reportResults'.
source dev-container-features-test-lib

REMOTE_USER="ubuntu"
if [ "$(id -un)" = "$REMOTE_USER" ]; then
  AS_USER="bash -lc"
else
  AS_USER="su - $REMOTE_USER -c"
fi

check "fzf is on PATH" bash -c "command -v fzf"
check "fzf starts" bash -c "fzf --version"

# The feature symlinks /usr/local/bin/fzf -> /opt/fzf/bin/fzf and chmods the
# tree a+rX, so an unprivileged user must be able to run it too.
# shellcheck disable=SC2086
check "fzf starts for the remote user" $AS_USER "fzf --version"

# Shell integration is the other half of what the feature installs; a missing
# block here means the binary works but the keybindings silently do not.
check "bash integration is wired up" \
  bash -c "grep -q 'fzf --bash' /home/$REMOTE_USER/.bashrc"

reportResults
