#!/bin/sh
set -eu
echo "Activating feature 'Opencode'"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this script must run as root." >&2
    exit 1
fi

USERNAME=${USERNAME:-$_REMOTE_USER}

if [ -n "${_REMOTE_USER_HOME}" ]; then
    USER_HOME=$( getent passwd "${USERNAME}" | cut -d: -f6 )
else
    USER_HOME=${_REMOTE_USER_HOME}
fi

if [ ! -d "${USER_HOME}" ]; then
    echo "ERROR: user (${USERNAME}) home directory (${USER_HOME}) does not exist." >&2
    exit 1
fi

pm_install() {
    pkgs="$1"
    echo "Installing:${pkgs}"
    if command -v apt-get >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive

        rm -rf /var/lib/apt/lists/*
        apt-get update -y

        # Word splitting on $pkgs is intentional here and below.
        # shellcheck disable=SC2086
        apt-get install -y $pkgs
        rm -rf /var/lib/apt/lists/*

    elif command -v apk >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        apk add --no-cache $pkgs

    elif command -v dnf >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        dnf install -y $pkgs
        dnf clean all

    elif command -v microdnf >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        microdnf install -y --nodocs $pkgs
        microdnf clean all

    elif command -v yum >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        yum install -y $pkgs
        yum clean all

    elif command -v zypper >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        zypper --non-interactive install $pkgs
        zypper clean --all

    elif command -v pacman >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        pacman -Sy --noconfirm --needed $pkgs
        rm -rf /var/cache/pacman/pkg/*

    else
        echo "Error: no supported package manager found." >&2
        echo "Install these manually and re-run:${pkgs}" >&2
        exit 1

    fi
}

# Only ask for what is actually missing.
PKGS=""
command -v sudo >/dev/null 2>&1 || PKGS="${PKGS} sudo"
command -v tar >/dev/null 2>&1 || PKGS="${PKGS} tar"
command -v curl >/dev/null 2>&1 || PKGS="${PKGS} curl"
if [ ! -e /etc/ssl/certs/ca-certificates.crt ] &&
    [ ! -e /etc/pki/tls/certs/ca-bundle.crt ]; then
# Installing curl normally drags in a CA bundle as a dependency, but if curl
# is ALREADY present and the bundle is not, nothing above adds a package and
# the download dies on certificate verification. This covers that case.
PKGS="${PKGS} ca-certificates"
fi
[ -z "$PKGS" ] || pm_install "$PKGS"

as_user() {
    sudo -u "$USERNAME" -H "$@"
}

as_user bash -c 'curl -fsSL https://opencode.ai/install | bash'

CONFIG_DIR="${USER_HOME}/.config/opencode"
as_user mkdir -p "${CONFIG_DIR}"
as_user cat > "${CONFIG_DIR}/tui.json" <<'EOF'
{
  "$schema": "https://opencode.ai/tui.json",
  "theme": "gruvbox"
}
EOF
