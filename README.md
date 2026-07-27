# Dev Container Repo
## Running Feature Tests
```bash
# All feature tests
devcontainer features test --skip-scenarios -p ./features -i ubuntu -u ubuntu

# by id
devcontainer features test --skip-scenarios -p ./features -f <id> -i ubuntu -u ubuntu
devcontainer features test --skip-scenarios -p ./features -f tmux -i ubuntu -u ubuntu

