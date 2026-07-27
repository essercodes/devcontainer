#!/bin/sh
set -eu

echo "Activating feature 'tmux'"

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: this script must run as root." >&2
  exit 1
fi

PM=""
for candidate in apt-get apk dnf microdnf yum zypper pacman; do
  if command -v "$candidate" >/dev/null 2>&1; then
    PM="$candidate"
    break
  fi
done

pm_install() {
  pkgs="$1"
  echo "Installing:${pkgs}"

  case "$PM" in
    apt-get)
      export DEBIAN_FRONTEND=noninteractive

      rm -rf /var/lib/apt/lists/*
      apt-get update -y

      # shellcheck disable=SC2086
      apt-get install -y $pkgs
      rm -rf /var/lib/apt/lists/*
      ;;

    apk)
      # shellcheck disable=SC2086
      apk add --no-cache $pkgs
      ;;

    dnf)
      # shellcheck disable=SC2086
      dnf install -y $pkgs
      dnf clean all
      ;;

    microdnf)
      # shellcheck disable=SC2086
      microdnf install -y --nodocs $pkgs
      microdnf clean all
      ;;

    yum)
      # shellcheck disable=SC2086
      yum install -y $pkgs
      yum clean all
      ;;

    zypper)
      # shellcheck disable=SC2086
      zypper --non-interactive install $pkgs
      zypper clean --all
      ;;

    pacman)
      # shellcheck disable=SC2086
      pacman -Sy --noconfirm --needed $pkgs
      rm -rf /var/cache/pacman/pkg/*
      ;;

    *)
      echo "Error: no supported package manager found." >&2
      echo "Install these manually and re-run:${pkgs}" >&2
      exit 1
      ;;
  esac
}

# Slim base images often carry only the handful of terminfo entries in the
# ncurses base package, which does not include .  Best effort: not every distro splits terminfo out this way.
terminfo_package() {
  case "$PM" in
    apt-get)              echo "ncurses-term" ;;
    apk)                  echo "ncurses-terminfo" ;;
    dnf | microdnf | yum) echo "ncurses-term" ;;
    zypper)               echo "terminfo-base" ;;
    *)                    echo "" ;;
  esac
}

if command -v tmux >/dev/null 2>&1; then
  echo "tmux already present: $(tmux -V)"
else
  pm_install " tmux"
fi

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
  printf '\n%s\n%s\n' "$CONF_MARKER" 'set -g status off' >> "$TMUX_CONF"
  echo "Status bar disabled in ${TMUX_CONF}"
fi
chmod a+r "$TMUX_CONF"

if ! command -v tmux >/dev/null 2>&1; then
  echo "Error: tmux is not on PATH after installation." >&2
  exit 1
fi

echo "Installed: $(tmux -V)"
