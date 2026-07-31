#!/bin/bash
 
op_env_run() {
    local cmd="" env_file="" no_mask=""
    local OPTIND=1 OPTARG

    local usage='Usage: op_env_run [options]   
    -c cmd                 command inject env file into
    -e env_file            op environment file path
    -m no_mask             include op --no-masking
    -h                     print this help'

    while getopts ':mc:e:h' flag; do
        case "${flag}" in
            m) no_mask=1 ;;
            c) cmd="${OPTARG}" ;;
            e) env_file="${OPTARG}" ;;
            h) printf '%s\n' "$usage"; return 0 ;;
            *) printf '%s\n' "$usage" >&2; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    if [[ -z "$cmd" ]]; then echo "cmd ($cmd) -c not set" >&2; return 1; fi
    if [[ -z "$env_file" ]]; then echo "env_file ($env_file) -e not set" >&2; return 1; fi
    
    local masking=""
    if [[ -n "$no_mask" ]]; then 
        masking="--no-masking"
    fi

    eval "
    ${cmd}() {
        op --account my.1password.com run --env-file=${env_file@Q} ${masking} -- ${cmd} \"\$@\"
    }
    "

}

op_env_run -m -c claude -e "${CONTAINER_WORKSPACE_FOLDER}/.devcontainer/claude.env"
op_env_run -m -c opencode -e "${CONTAINER_WORKSPACE_FOLDER}/.devcontainer/opencode.env"

