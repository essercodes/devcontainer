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

check "config was cloned" bash -c "[ -d /home/$REMOTE_USER/.config/nvim/.git ]"
check "config is owned by the remote user" \
  bash -c "[ \"\$(stat -c '%U' /home/$REMOTE_USER/.config/nvim)\" = '$REMOTE_USER' ]"

check "tree-sitter cli starts" bash -c "tree-sitter --version"

# Booting headless with the real config is the actual smoke test: a Lua error in
# any plugin spec makes nvim exit non-zero here even though 'nvim --version'
# would still succeed.
# shellcheck disable=SC2086
check "nvim starts with the config" $AS_USER "nvim --headless +qa"

# lazy.nvim installs plugins here. Without it the config loaded but the sync
# step in install.sh silently did nothing.
check "plugins were installed" \
  bash -c "[ -d /home/$REMOTE_USER/.local/share/nvim/lazy ]"

reportResults
