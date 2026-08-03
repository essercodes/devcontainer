#!/usr/bin/env bash

set -euo pipefail

TARGET_USER=${AS_NON_ADMIN_USER:-nonAdmin}

usage() {
    cat <<'EOF'
Usage: as_non_admin [-e <env_file>] [-u <user>] <command> [args...]

  -e <env_file>  preserve every variable named in <env_file> across sudo
  -u <user>      run as <user> (default: nonAdmin, or $AS_NON_ADMIN_USER)
  -h             show this help
EOF
}

die() {
    printf 'as_non_admin: %s\n' "$1" >&2
    exit "${2:-1}"
}

env_keys() {
  local line key out=()
  while IFS= read -r line || [[ -n $line ]]; do
    [[ $line == *=* ]] || continue
    key=${line%%=*}
    key=$(echo "$key" | xargs)
    [[ -n $key && $key != \#* ]] && out+=("$key")
  done < "$1"
  local IFS=,
  printf '%s\n' "${out[*]}"
}

main() {
    local env_file=''
    local -a preserve
    local OPTIND=1 OPTARG

    while getopts ':e:h' flag; do
        case "${flag}" in
            e) env_file="${OPTARG}" ;;
            h) printf '%s\n' "$usage"; return 0 ;;
            :) usage >&2; die "missing argument for -$OPTARG" ;;
            *) usage >&2; die "unknown option -$OPTARG" ;;
        esac
    done
    shift $((OPTIND - 1))

    if (( $# == 0 )); then
        printf '%s\n' "$usage" >&2
        return 1
    fi

    preserve=()
    if [[ -n "$env_file" ]]; then
        local keys
        keys="$(env_keys "$env_file")" || return 1
        [[ -n "$keys" ]] && preserve+=("--preserve-env=${keys}")
    fi

    exec sudo -H "${preserve[@]}" -u "${TARGET_USER}" -- env "PATH=$PATH" "$@"
}

main "$@"
