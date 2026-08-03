dca() {
    local workspace_folder="."
    local session_name="main"
    local remote_user="max"
    local include_token=
    local verbose=
    local OPTIND=1 OPTARG flag dir op_token
    local -a dc

    local usage='Usage: dca [options]   
    -t                     include or update 1Password service token
    -w <workspace_folder>  default: "."
    -s <session_name>      tmux session, default: "main"
    -r <remote_user>       user to with op cred permissions
    -v                     verbose
    -h                     print this help'

    while getopts 'ts:w:r:vh' flag; do
        case "${flag}" in
            t) include_token=1 ;;
            s) session_name="${OPTARG}" ;;
            w) workspace_folder="${OPTARG}" ;;
            r) remote_user="${OPTARG}" ;;
            v) verbose=1 ;;
            h) printf '%s\n' "$usage"; return 0 ;;
            *) printf '%s\n' "$usage" >&2; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ ! -d "${workspace_folder}/.devcontainer" ]; then
        echo "Not a valid devcontainer directory" >&2
        return 1
    fi

    dc=(devcontainer exec --workspace-folder "${workspace_folder}" --)

    if [ -n "$include_token" ]; then
        if [ -n "$verbose" ]; then echo "Getting OP token"; fi

        dir=$(cd -- "${workspace_folder}" 2>/dev/null && pwd -P) || return 1
        dir=$(printf '%s' "${dir##*/}" | tr ' ' '_')

        op_token=$(
            op --account my.1password.com service-account create \
                "devcontainer-${dir}-$(date +%Y%m%d-%H%M%S)" \
                --expires-in=3h \
                --raw \
                --vault Devcontainer:read_items,write_items
            ) || return 1

        secret_file="/home/${remote_user}/op_secret"

        "${dc[@]}" bash -c "touch ${secret_file} && \
            echo ${op_token} > ${secret_file} && \
            chown ${remote_user}:${remote_user} ${secret_file} && \
            chmod 0600 ${secret_file}"
    fi

    "${dc[@]}" tmux new -A -D -t "${session_name}"
}
