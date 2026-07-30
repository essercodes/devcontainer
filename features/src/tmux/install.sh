#!/bin/sh
set -eu

echo "Activating feature 'tmux'"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this script must run as root." >&2
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
command -v tmux >/dev/null 2>&1 || PKGS="${PKGS} tmux"
if [ ! -e /etc/ssl/certs/ca-certificates.crt ] &&
    [ ! -e /etc/pki/tls/certs/ca-bundle.crt ]; then
# Installing curl normally drags in a CA bundle as a dependency, but if curl
# is ALREADY present and the bundle is not, nothing above adds a package and
# the download dies on certificate verification. This covers that case.
PKGS="${PKGS} ca-certificates"
fi
[ -z "$PKGS" ] || pm_install "$PKGS"


# Without tmux-256color tmux starts but reports the terminal as unsuitable, so 
# the extended set is pulled in alongside.
if ! infocmp tmux-256color >/dev/null 2>&1; then
    TERMINFO_PKG="$(terminfo_package)"
    if [ -n "$TERMINFO_PKG" ]; then
        pm_install " ${TERMINFO_PKG}" ||
            echo "Warning: could not install ${TERMINFO_PKG}; tmux-256color may be unavailable." >&2
    fi
fi

# Written system-wide rather than into the user's home so that a dotfiles repo
# bringing its own ~/.tmux.conf is not clobbered. This file is read first.
TMUX_CONF="/etc/tmux.conf"

# A sentinel comment written above the block we add. Repeated activations and
# rebuilds look for it and bail, so the settings do not stack up. Changing this
# string orphans the blocks written by earlier versions of the feature.
CONF_MARKER="# tmux defaults (devcontainer feature)"

[ -e "$TMUX_CONF" ] || : > "$TMUX_CONF"
if ! grep -qF "$CONF_MARKER" "$TMUX_CONF" 2>/dev/null; then
    cat << EOF >> "$TMUX_CONF"
$CONF_MARKER
set -g status-position top
set -g mouse on
set-window-option -g mode-keys vi
bind-key -T copy-mode-vi v send -X begin-selection
bind-key -T copy-mode-vi V send -X select-line
EOF
    echo "Status bar disabled in ${TMUX_CONF}"
fi
chmod a+r "$TMUX_CONF"

if ! command -v tmux >/dev/null 2>&1; then
    echo "Error: tmux is not on PATH after installation." >&2
    exit 1
fi

echo "Installed: $(tmux -V)"
