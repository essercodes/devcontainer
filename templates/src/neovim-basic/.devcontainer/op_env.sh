#!/bin/bash

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

as_non_admin() {
    local env_file=''
    local -a preserve
    local OPTIND=1 OPTARG
    local usage='Usage: as_non_admin [-e <env_file>] <command> [args...]'

    while getopts ':e:h' flag; do
        case "${flag}" in
            e) env_file="${OPTARG}" ;;
            h) printf '%s\n' "$usage"; return 0 ;;
            :) printf 'Missing argument for -%s\n%s\n' "$OPTARG" "$usage" >&2; return 1 ;;
            *) printf 'Unknown option -%s\n%s\n' "$OPTARG" "$usage" >&2; return 1 ;;
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

    sudo "${preserve[@]}" -u nonAdmin -- env "PATH=$PATH" "$@"
}

op_env_run() {
    local cmd="" env_file="" no_mask="" bin=""
    local OPTIND=1 OPTARG

    local usage='Usage: op_env_run [options]   
    -c cmd                 command inject env file into
    -b bin                 binary path; cmd if not set
    -e env_file            op environment file path
    -m no_mask             include op --no-masking
    -h                     print this help'

    while getopts ':mc:b:e:h' flag; do
        case "${flag}" in
            m) no_mask=1 ;;
            c) cmd="${OPTARG}" ;;
            b) bin="${OPTARG}" ;;
            e) env_file="${OPTARG}" ;;
            h) printf '%s\n' "$usage"; return 0 ;;
            *) printf '%s\n' "$usage" >&2; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    if [[ -z "$cmd" ]]; then echo "cmd ($cmd) -c not set" >&2; return 1; fi

    if [[ -z "$bin" ]]; then bin=${cmd}; fi

    local masking=""
    if [[ -n "$no_mask" ]]; then 
        masking="--no-masking"
    fi

    local secret_file="/home/${REMOTE_USER}/op_secret"

    local envs=""
    local op_prefix=""
    if [[ -n ${env_file} ]]; then
        op_prefix="OP_SERVICE_ACCOUNT=\$(cat ${secret_file@Q}) \
            op --account my.1password.com run --env-file=${env_file@Q} ${masking} --"

        envs="-e ${env_file}"
    fi

    eval "
    ${cmd}() {
        ${op_prefix} as_non_admin ${envs} ${bin} \"\$@\"
    }
    "
}

CLAUDE_ENV_FILE="${CONTAINER_WORKSPACE_FOLDER}/.devcontainer/claude.env"
cat <<EOF > "$CLAUDE_ENV_FILE"
CLAUDE_CODE_OAUTH_TOKEN = op://Devcontainer/CLAUDE_CODE_OAUTH_TOKEN/credential
EOF

OPENCODE_ENV_FILE="${CONTAINER_WORKSPACE_FOLDER}/.devcontainer/opencode.env"
cat <<EOF > "$OPENCODE_ENV_FILE"
OPENROUTER_API_KEY = op://Devcontainer/OPENROUTER_API_KEY/credential
EOF

op_env_run -m -c claude -e "$CLAUDE_ENV_FILE" \
    -b "/home/nonAdmin/.local/bin/claude"
op_env_run -m -c opencode -e "$OPENCODE_ENV_FILE" \
    -b "/home/nonAdmin/.opencode/bin/opencode"
op_env_run -c pnpm
op_env_run -c npm
op_env_run -c python
op_env_run -c python3
op_env_run -c pip 
op_env_run -c pip3
op_env_run -c cargo

