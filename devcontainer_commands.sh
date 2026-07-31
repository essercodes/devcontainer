dca() {
    local workspace_folder="." 
    local session_name="main" 
    local include_token= 
    local verbose=
    local OPTIND=1 OPTARG flag dir op_token
    local -a dc new_env

    local usage='Usage: dca [options]   
    -t                     include or update 1Password service token
    -w <workspace_folder>  default: "."
    -s <session_name>      tmux session, default: "main"
    -v                     verbose
    -h                     print this help'

    while getopts 'ts:w:vh' flag; do
        case "${flag}" in
            t) include_token=1 ;;
            s) session_name="${OPTARG}" ;;
            w) workspace_folder="${OPTARG}" ;;
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
                --expires-in=1d \
                --raw \
                --vault Devcontainer:read_items,write_items
            ) || return 1
    fi

    if "${dc[@]}" tmux has-session -t "${session_name}" 2>/dev/null; then
        if [ -n "$verbose" ]; then echo "Session exists; connecting..."; fi

        if [ -n "$include_token" ]; then
            # only affects panes created afterward
            "${dc[@]}" tmux set-environment -t "${session_name}" \
                OP_SERVICE_ACCOUNT "${op_token}"
        fi

        "${dc[@]}" tmux attach -d -t "${session_name}"
    else
        if [ -n "$verbose" ]; then echo "Session does not exist; starting..."; fi

        new_env=()
        if [ -n "$include_token" ]; then new_env=(-e "OP_SERVICE_ACCOUNT=${op_token}"); fi

        "${dc[@]}" tmux new "${new_env[@]}" -s "${session_name}"
    fi
}
