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

# The upstream installer drops the binary in the remote user's home and appends
# a PATH line to their rc files, so check the file directly before relying on
# PATH -- that separates "not installed" from "installed but not on PATH".
check "claude binary was installed" bash -c "
  [ -x /home/$REMOTE_USER/.local/bin/claude ] ||
  [ -x /home/$REMOTE_USER/.claude/local/claude ] ||
  [ -x /usr/local/bin/claude ]
"

# shellcheck disable=SC2086
check "claude is on the remote user's PATH" $AS_USER "command -v claude"

# shellcheck disable=SC2086
check "claude starts" $AS_USER "claude --version"

reportResults
