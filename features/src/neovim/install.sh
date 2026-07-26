#!/bin/sh
set -eu

VERSION="${VERSION:-latest}"
INSTALL_DIR="/opt/nvim"
BIN_LINK="/usr/local/bin/nvim"

echo "Activating feature 'Neovim' (version: ${VERSION})"

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: this script must run as root." >&2
  exit 1
fi

ARCHITECTURE="${ARCHITECTURE:-$(uname -m)}"
case "$ARCHITECTURE" in
  x86_64 | amd64)  NVIM_ARCH="x86_64" ;;
  aarch64 | arm64) NVIM_ARCH="arm64" ;;
  *)
    echo "Error: unsupported architecture '${ARCHITECTURE}'." >&2
    exit 1
    ;;
esac

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
command -v curl >/dev/null 2>&1 || PKGS="${PKGS} curl"
command -v tar >/dev/null 2>&1 || PKGS="${PKGS} tar"
if [ ! -e /etc/ssl/certs/ca-certificates.crt ] &&
  [ ! -e /etc/pki/tls/certs/ca-bundle.crt ]; then
  # Installing curl normally drags in a CA bundle as a dependency, but if curl
  # is ALREADY present and the bundle is not, nothing above adds a package and
  # the download dies on certificate verification. This covers that case.
  PKGS="${PKGS} ca-certificates"
fi
[ -z "$PKGS" ] || pm_install "$PKGS"

ASSET="nvim-linux-${NVIM_ARCH}.tar.gz"
if [ "$VERSION" = "latest" ]; then
  BASE_URL="https://github.com/neovim/neovim/releases/latest/download"

else
  # Accept both "0.11.0" and "v0.11.0".
  BASE_URL="https://github.com/neovim/neovim/releases/download/v${VERSION#v}"

fi

# Removed on exit so the tarball does not end up baked into the image layer.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading ${BASE_URL}/${ASSET}"
curl -fsSL --retry 3 --retry-delay 2 -o "${TMP_DIR}/${ASSET}" "${BASE_URL}/${ASSET}"

if command -v sha256sum >/dev/null 2>&1 &&
  curl -fsSL --retry 3 -o "${TMP_DIR}/${ASSET}.sha256sum" "${BASE_URL}/${ASSET}.sha256sum"; then
  (cd "$TMP_DIR" && sha256sum -c "${ASSET}.sha256sum")
else
  echo "Warning: checksum unavailable, skipping verification." >&2
fi

tar -C "$TMP_DIR" -xzf "${TMP_DIR}/${ASSET}"
SRC_DIR="${TMP_DIR}/nvim-linux-${NVIM_ARCH}"
if [ ! -x "${SRC_DIR}/bin/nvim" ]; then
  echo "Error: ${SRC_DIR}/bin/nvim missing; unexpected archive layout." >&2
  exit 1
fi

rm -rf "$INSTALL_DIR"
mv "$SRC_DIR" "$INSTALL_DIR"

# Readable and executable for every user in the container, not just root.
chmod -R a+rX "$INSTALL_DIR"
rm -f "$BIN_LINK"
ln -s "${INSTALL_DIR}/bin/nvim" "$BIN_LINK"

echo "Installed: $("$BIN_LINK" --version | head -n 1)"
