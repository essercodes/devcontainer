# Dev Container Repo
## Running Feature Tests
```bash
# All feature tests
devcontainer features test --skip-scenarios -p ./features -i ubuntu -u ubuntu

# Global only
devcontainer features test --global-scenarios-only -p ./features -i ubuntu -u ubuntu

# By feature id
devcontainer features test --skip-scenarios -p ./features -f <ids> -i ubuntu -u ubuntu
devcontainer features test --skip-scenarios -p ./features -f tmux neovim -i ubuntu -u ubuntu
```

## neovim-basic Template

```bash
devcontainer templates apply --workspace-folder . \
    --template-id ghcr.io/essercodes/devcontainer/neovim-basic:latest
    
```

### Connecting
Source the connection command.
```bash
source devcontainer_commands.sh
```

Connect (or re-connect) to the session.
```bash
dca -t
```

### Detach from session
If tmux is running nested on the host system:   <C-b><C-b>d
If tmux is running on the NOT nested on host:   <C-b>d
