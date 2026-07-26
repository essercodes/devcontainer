# Dev Container Repo
## Install Neovim Development Environment
`/path/to/project/.devcontainer/devcontainer.json`
 .devcontainer/devcontainer.json
```json
{
	"image": "ubuntu",
	"features": {
        "ghcr.io/essercodes/devcontainer/neovim-config": {},
        "ghcr.io/essercodes/devcontainer/claudecode": {}
    },
	"remoteUser": "ubuntu"
}
```
```sh
# build and launch container (optionally add --remove-existing-container --build-no-cache for re-build)
devcontainer up

# connect
devcontainer exec bash # or nvim
```

## Avaliable Features
```json
{
    "features": {
        "ghcr.io/essercodes/devcontainer/neovim-config": {},
        "ghcr.io/essercodes/devcontainer/neovim": {},
        "ghcr.io/essercodes/devcontainer/claudecode": {}
        "ghcr.io/essercodes/devcontainer/opencode": {},
    }
}
```

