#!/bin/bash
set -eu
echo -e "Activating feature 'Opencode'"

curl -fsSL https://opencode.ai/install | bash
