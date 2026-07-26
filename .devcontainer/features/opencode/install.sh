#!/bin/sh
set -eu
echo "Activating feature 'Opencode'"

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

as_user() {
  sudo -u "$USERNAME" -H "$@"
}

as_user bash -c 'curl -fsSL https://opencode.ai/install | bash'
