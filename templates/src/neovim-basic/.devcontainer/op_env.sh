#!/bin/bash

env_keys() {
  awk -F= '/=/ {
    key = $1
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
    if (key != "" && key !~ /^#/)
      printf "%s%s", (n++ ? "," : ""), key
  }
  END { print "" }' "$1"
}

as_non_admin() {
    local env_file;
    local -a preserve;
    local OPTIND=1 OPTARG

    local usage='Usage: as_non_admin -e <env_file>'

    while getopts ':e:h' flag; do
        case "${flag}" in
            e) env_file="${OPTARG}" ;;
            h) printf '%s\n' "$usage"; return 0 ;;
            *) printf '%s\n' "$usage"; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    preserve=()
    if [[ -n "${env_file}" ]]; then  
        preserve=("--preserve-env=$(env_keys "${env_file}")")
    fi

    preserve=(sudo "${preserve[@]}" -u nonAdmin)
    echo "${preserve[@]}"
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
    if [[ -z "$env_file" ]]; then echo "env_file ($env_file) -e not set" >&2; return 1; fi

    if [[ -z "$bin" ]]; then bin=${cmd}; fi

    local masking=""
    if [[ -n "$no_mask" ]]; then 
        masking="--no-masking"
    fi

    secret_file="/home/${REMOTE_USER}/op_secret"
    eval "
    ${cmd}() {
        OP_SERVICE_ACCOUNT=\$(cat ${secret_file}) op --account my.1password.com run \
            --env-file=${env_file@Q} ${masking} -- \
            $(as_non_admin -e "${env_file}") ${bin} \"\$@\"
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


