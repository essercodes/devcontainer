CLAUDE_ENV_FILE="${CONTAINER_WORKSPACE_FOLDER}/.devcontainer/claude.env"
cat <<EOF > "$CLAUDE_ENV_FILE"
CLAUDE_CODE_OAUTH_TOKEN = op://Devcontainer/CLAUDE_CODE_OAUTH_TOKEN/credential
EOF

OPENCODE_ENV_FILE="${CONTAINER_WORKSPACE_FOLDER}/.devcontainer/opencode.env"
cat <<EOF > "$OPENCODE_ENV_FILE"
OPENROUTER_API_KEY = op://Devcontainer/OPENROUTER_API_KEY/credential
EOF

shortcut_na() { eval "$(command shortcut_as_non_admin.sh "$@")"; }

shortcut_na -m -c claude -e "$CLAUDE_ENV_FILE" \
    -b "/home/nonAdmin/.local/bin/claude"
shortcut_na -m -c opencode -e "$OPENCODE_ENV_FILE" \
    -b "/home/nonAdmin/.opencode/bin/opencode"
shortcut_na -c pnpm
shortcut_na -c npm
shortcut_na -c python
shortcut_na -c python3
shortcut_na -c pip 
shortcut_na -c pip3
shortcut_na -c cargo

opencode_serve() {
    opencode serve --hostname localhost --port 4096
}

