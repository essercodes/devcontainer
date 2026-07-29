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

check "op is on PATH" bash -c "command -v op"
check "op starts" bash -c "op --version"
check "op starts as remoteUser" bash -c "$AS_USER op --version"

reportResults
