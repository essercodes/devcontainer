#!/bin/sh
set -eu

VERSION="${VERSION:-latest}"
INSTALL_DIR="/opt/fzf"
BIN_LINK="/usr/local/bin/fzf"
REPO="junegunn/fzf"

echo "Activating feature 'fzf' (version: ${VERSION})"

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: this script must run as root." >&2
  exit 1
fi

ARCHITECTURE="${ARCHITECTURE:-$(uname -m)}"
case "$ARCHITECTURE" in
  x86_64 | amd64)  FZF_ARCH="amd64" ;;
  aarch64 | arm64) FZF_ARCH="arm64" ;;
  armv7l | armv7)  FZF_ARCH="armv7" ;;
  ppc64le)         FZF_ARCH="ppc64le" ;;
  riscv64)         FZF_ARCH="riscv64" ;;
  s390x)           FZF_ARCH="s390x" ;;
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


# Release assets embed the version number (fzf-0.74.1-linux_amd64.tar.gz), so
# the /releases/latest/download/ shortcut cannot be used: there is no
# version-independent asset name to point it at. Resolve the tag first.
#
# The HTML redirect is preferred over api.github.com because the API is rate
# limited to 60 unauthenticated requests per hour per IP, which is easy to
# exhaust from CI or a shared NAT. The API is kept as a fallback.
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

resolve_latest() {
  effective_url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    "https://github.com/${REPO}/releases/latest" 2>/dev/null || true)"
  case "$effective_url" in
    */releases/tag/*)
      tag="${effective_url##*/tag/}"
      printf '%s\n' "${tag#v}"
      return 0
      ;;
  esac

  echo "Note: redirect lookup failed, falling back to the GitHub API." >&2
  curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" |
    sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([^"]*\)".*/\1/p' |
    head -n 1
}

if [ "$VERSION" = "latest" ]; then
  VERSION="$(resolve_latest)"
  if [ -z "$VERSION" ]; then
    echo "Error: could not resolve the latest fzf release." >&2
    exit 1
  fi
  echo "Resolved 'latest' to ${VERSION}"
else
  # Accept both "0.74.1" and "v0.74.1".
  VERSION="${VERSION#v}"
fi

ASSET="fzf-${VERSION}-linux_${FZF_ARCH}.tar.gz"
SUMS="fzf_${VERSION}_checksums.txt"
BASE_URL="https://github.com/${REPO}/releases/download/v${VERSION}"

# Removed on exit so the tarball does not end up baked into the image layer.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading ${BASE_URL}/${ASSET}"
curl -fsSL --retry 3 --retry-delay 2 -o "${TMP_DIR}/${ASSET}" "${BASE_URL}/${ASSET}"

# fzf ships one checksums file covering every asset in the release, not a
# per-asset .sha256sum. Pull out just our line; feeding the whole file to
# sha256sum -c would fail on the assets we did not download, and
# --ignore-missing is GNU-only (busybox on Alpine does not have it).
if command -v sha256sum >/dev/null 2>&1 &&
  curl -fsSL --retry 3 --retry-delay 2 -o "${TMP_DIR}/${SUMS}" "${BASE_URL}/${SUMS}"; then

  awk -v f="$ASSET" '$2 == f || $2 == "*" f' "${TMP_DIR}/${SUMS}" \
    > "${TMP_DIR}/expected.sha256"

  if [ -s "${TMP_DIR}/expected.sha256" ]; then
    (cd "$TMP_DIR" && sha256sum -c expected.sha256)
  else
    echo "Error: ${ASSET} not listed in ${SUMS}." >&2
    exit 1
  fi
else
  echo "Warning: checksum unavailable, skipping verification." >&2
fi

# The linux tarball contains a bare 'fzf' executable at the archive root; there
# is no top-level directory and no bin/ subdirectory.
tar -C "$TMP_DIR" -xzf "${TMP_DIR}/${ASSET}"
if [ ! -f "${TMP_DIR}/fzf" ]; then
  echo "Error: ${TMP_DIR}/fzf missing; unexpected archive layout." >&2
  exit 1
fi

rm -rf "$INSTALL_DIR"
mkdir -p "${INSTALL_DIR}/bin"
# Readable and executable for every user in the container, not just root.
install -m 0755 "${TMP_DIR}/fzf" "${INSTALL_DIR}/bin/fzf"
chmod -R a+rX "$INSTALL_DIR"

rm -f "$BIN_LINK"
ln -s "${INSTALL_DIR}/bin/fzf" "$BIN_LINK"

# A sentinel comment written above each block we add. append_rc looks for it
# and bails if it is already there, so rebuilds and repeated activations do not
# stack up duplicate blocks in the rc files. Changing this string orphans the
# blocks written by earlier versions of the feature.
RC_MARKER="# fzf shell integration (devcontainer feature)"

append_rc() {
  rc="$1"
  body="$2"

  [ -e "$rc" ] || : > "$rc"
  if grep -qF "$RC_MARKER" "$rc" 2>/dev/null; then
    return 0
  fi

  printf '\n%s\n%s\n' "$RC_MARKER" "$body" >> "$rc"
  chown "$_REMOTE_USER:" "$rc" 2>/dev/null || true
}

# shellcheck disable=SC2016
append_rc "$_REMOTE_USER_HOME/.bashrc" 'eval "$(fzf --bash)"'

append_rc "$_REMOTE_USER_HOME/.zshrc" 'source <(fzf --zsh)'

echo "Installed: $("$BIN_LINK" --version | head -n 1)"
