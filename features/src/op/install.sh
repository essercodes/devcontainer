#!/bin/sh
set -eu

echo "Activating feature '1Password CLI'"

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

if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive

    rm -rf /var/lib/apt/lists/*
    apt-get update -y

    # Only ask for what is actually missing.
    PKGS=""
    command -v curl >/dev/null 2>&1 || PKGS="${PKGS} curl"
    command -v gpg >/dev/null 2>&1 || PKGS="${PKGS} gpg"

    if [ ! -e /etc/ssl/certs/ca-certificates.crt ] &&
        [ ! -e /etc/pki/tls/certs/ca-bundle.crt ]; then
        # Installing curl normally drags in a CA bundle as a dependency, but if curl
        # is ALREADY present and the bundle is not, nothing above adds a package and
        # the download dies on certificate verification. This covers that case.
        PKGS="${PKGS} ca-certificates"
    fi

    # shellcheck disable=SC2086
    [ -z "$PKGS" ] || apt-get install -y $PKGS

    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
        tee /etc/apt/sources.list.d/1password.list

    mkdir -p /etc/debsig/policies/AC2D62742012EA22/

    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
        tee /etc/debsig/policies/AC2D62742012EA22/1password.pol

    mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22

    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

    apt update -y
    apt install 1password-cli

    rm -rf /var/lib/apt/lists/*

elif command -v apk >/dev/null 2>&1; then
    apk update

    # Only ask for what is actually missing.
    PKGS=""
    command -v wget >/dev/null 2>&1 || PKGS="${PKGS} wget"
    
    # shellcheck disable=SC2086
    [ -z "$PKGS" ] || apk install -y $PKGS

    echo https://downloads.1password.com/linux/alpinelinux/stable/ >> /etc/apk/repositories
    wget https://downloads.1password.com/linux/keys/alpinelinux/support@1password.com-61ddfc31.rsa.pub -P /etc/apk/keys

    apk update
    apk add 1password-cli

elif command -v dnf >/dev/null 2>&1; then
    rpm --import https://downloads.1password.com/linux/keys/1password.asc
    sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'

    dnf check-update -y 1password-cli
    dnf install -y 1password-cli

elif command -v yum >/dev/null 2>&1; then
    rpm --import https://downloads.1password.com/linux/keys/1password.asc
    sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
    
    yum check-update -y 1password-cli
    yum install -y 1password-cli
    yum clean all

else
    # Manual Install
    ARCHITECTURE="${ARCHITECTURE:-$(uname -m)}"
    case "$ARCHITECTURE" in
        x86_64 | amd64)  ARCH="x86_64" ;;
        aarch64 | arm64) ARCH="arm64" ;;
        *)
            echo "Error: unsupported architecture '${ARCHITECTURE}'." >&2
            exit 1
            ;;
    esac

    # Only ask for what is actually missing.
    PKGS=""
    command -v curl >/dev/null 2>&1 || PKGS="${PKGS} wget"
    command -v unzip >/dev/null 2>&1 || PKGS="${PKGS} unzip"
    [ -z "$PKGS" ] || pm_install "$PKGS"

    wget "https://cache.agilebits.com/dist/1P/op2/pkg/v2.35.0/op_linux_${ARCH}_v2.35.0.zip" -O op.zip
    
    unzip -d op op.zip

    mv op/op /usr/local/bin/

    rm -r op.zip op

    groupadd -f onepassword-cli
    chgrp onepassword-cli /usr/local/bin/op

    chmod g+s /usr/local/bin/op

fi

echo "Installed: $(op --version)"
