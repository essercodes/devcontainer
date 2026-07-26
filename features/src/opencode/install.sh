#!/bin/sh
set -eu
echo "Activating feature 'Opencode'"

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: this script must run as root." >&2
  exit 1
fi

as_user() {
  sudo -u "$_REMOTE_USER" -H "$@"
}

as_user bash -c 'curl -fsSL https://opencode.ai/install | bash'
