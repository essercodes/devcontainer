#!/bin/sh
set -eu

echo "Activating feature 'Neovim Config'"

NVIM_CONFIG_URL="${CONFIGURL:-https://github.com/essercodes/neovim-config}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: this script must run as root." >&2
  exit 1
fi

NVIM_CONFIG_DIR="${_REMOTE_USER_HOME}/.config/nvim"


echo "## Install Treesitter dependencies ##"
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
command -v clang >/dev/null 2>&1 || PKGS="${PKGS} clang"
command -v git >/dev/null 2>&1 || PKGS="${PKGS} git"
if [ ! -e /etc/ssl/certs/ca-certificates.crt ] &&
  [ ! -e /etc/pki/tls/certs/ca-bundle.crt ]; then
  # Installing curl normally drags in a CA bundle as a dependency, but if curl
  # is ALREADY present and the bundle is not, nothing above adds a package and
  # the download dies on certificate verification. This covers that case.
  PKGS="${PKGS} ca-certificates"
fi
[ -z "$PKGS" ] || pm_install "$PKGS"

if ! command -v cargo >/dev/null 2>&1; then
  echo "Error: cargo not found. Add a Rust Feature to this Feature's" >&2
  echo "installsAfter, or drop tree-sitter-cli if the config does not need it." >&2
  exit 1
fi

echo "## Install tree-sitter CLI ##"
cargo install --locked --root /usr/local tree-sitter-cli

as_user() {
  sudo -u "$_REMOTE_USER" -H env "PATH=$PATH" "$@"
}

echo "## Clone config ##"
as_user mkdir -p "${_REMOTE_USER_HOME}/.config"
as_user git clone --depth 1 "$NVIM_CONFIG_URL" "$NVIM_CONFIG_DIR"

echo "## Install Neovim plugins ##"
as_user nvim --headless "+Lazy! sync" +qa

echo "## Install LSP Servers + Tools ##"
as_user nvim --headless "+Lazy! load mason.nvim" "+MasonInstallAll" +qa

echo "Done. Config installed to ${NVIM_CONFIG_DIR} for user ${_REMOTE_USER}."
