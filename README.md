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
dca
```

Connect (or re-connect) and inject 1Password service account token.
```bash
dca -t
```
#### Error: `(400) Bad Request: The structure of request was invalid.`
1Password has a limit of 100 service accounts per account. If the limit is reached they need to be
revoked on the 1Password website. If the limit is reach you will see this error.

### Detach from session
If tmux is running nested on the host system:   <M-b>d
