# Dev Container Repo
## Running Feature Tests
```bash
# All feature tests
devcontainer features test --skip-scenarios -p ./features -i ubuntu -u ubuntu

# by id
devcontainer features test --skip-scenarios -p ./features -f <id> -i ubuntu -u ubuntu
devcontainer features test --skip-scenarios -p ./features -f tmux -i ubuntu -u ubuntu
```

## Connect
Connect (or reconnect) to the terminal session when using the neovim-basic template.
```bash
devcontainer exec --workspace-folder . -- tmux new -A -D -s main
```

```bash
dcx() { devcontainer exec --workspace-folder "${1:-.}" -- tmux new -A -D -s "${TMUX_SESSION:-main}"; }
```

## Detach
If tmux is running on the host:     <C-b><C-b>d
If tmux is running on the NOT host: <C-b>d
