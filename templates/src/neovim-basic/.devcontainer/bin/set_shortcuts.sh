persistent-op_env_run() { eval "$(command op_env_run.sh "$@")"; }

CLAUDE_ENV_FILE="/home/${REMOTE_USER}/claude.env"
cat <<EOF > "$CLAUDE_ENV_FILE"
CLAUDE_CODE_OAUTH_TOKEN = op://Devcontainer/CLAUDE_CODE_OAUTH_TOKEN/credential
EOF

persistent-op_env_run -m -c claude -e "$CLAUDE_ENV_FILE" \
    -b "/home/nonAdmin/.local/bin/claude"

OPENCODE_ENV_FILE="/home/${REMOTE_USER}/opencode.env"
cat <<EOF > "$OPENCODE_ENV_FILE"
OPENROUTER_API_KEY = op://Devcontainer/OPENROUTER_API_KEY/credential
EOF

# nvim generates OPENCODE_SERVER_PASSWORD per session; keep it across sudo
persistent-op_env_run -m -c opencode -e "$OPENCODE_ENV_FILE" -p OPENCODE_SERVER_PASSWORD \
    -b "/home/nonAdmin/.opencode/bin/opencode"

NPM_ENV_FILE="/home/${REMOTE_USER}/npm.env"
cat <<EOF > "$NPM_ENV_FILE"
GITHUB_PACKAGES_READ_TOKEN = op://Devcontainer/GITHUB_PACKAGES_READ_TOKEN/token
EOF

persistent-op_env_run -m -c npm -e "$NPM_ENV_FILE"
persistent-op_env_run -m -c pnpm -e "$NPM_ENV_FILE"
persistent-op_env_run -m -c npx -e "$NPM_ENV_FILE"
persistent-op_env_run -m -c pnpx -e "$NPM_ENV_FILE"

AWS_ENV_FILE="/home/${REMOTE_USER}/aws.env"
cat <<EOF > "$AWS_ENV_FILE"
AWS_ACCESS_KEY_ID = "op://Devcontainer/AWS Access Key/access key id"
AWS_SECRET_ACCESS_KEY = "op://Devcontainer/AWS Access Key/secret access key"
AWS_REGION = "op://Devcontainer/AWS Access Key/region"
EOF

persistent-op_env_run -m -c aws -e "$AWS_ENV_FILE"
persistent-op_env_run -m -c terraform -e "$AWS_ENV_FILE"

persistent-op_env_run -c python
persistent-op_env_run -c python3
persistent-op_env_run -c pip 
persistent-op_env_run -c pip3
persistent-op_env_run -c cargo
