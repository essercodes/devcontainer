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

check "nvim is on PATH" bash -c "command -v nvim"
check "nvim starts" bash -c "nvim --version"

# --headless +qa boots the full editor and exits, which catches a broken
# runtime/ directory that 'nvim --version' alone would not.
check "nvim boots and exits cleanly" bash -c "nvim --headless +qa"

# shellcheck disable=SC2086
check "nvim starts for the remote user" $AS_USER "nvim --headless +qa"

reportResults
