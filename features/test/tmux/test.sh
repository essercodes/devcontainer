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

check "tmux is on PATH" bash -c "command -v tmux"
check "tmux starts" bash -c "tmux -V"

# tmux needs a working server, not just a binary: start a detached session,
# confirm the server sees it, then tear it down.
# shellcheck disable=SC2086
check "tmux server runs a session" $AS_USER \
  "tmux new-session -d -s smoke 'sleep 30' && tmux has-session -t smoke && tmux kill-session -t smoke"

reportResults
