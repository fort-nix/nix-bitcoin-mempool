#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Run tests
# See also: https://github.com/fort-nix/nix-bitcoin/blob/master/test/README.md

# Build all tests
nix flake check

# Build specific tests
nix build --no-link --print-out-paths -L .#tests.default
nix build --no-link --print-out-paths -L .#tests.netnsRegtest

# Run a Python test shell inside the test VM
nix run .#tests.default.vm.run -- --debug

# Run test VM. No tests are executed.
nix run .#tests.default.vm

# Run test node in a container. Requires extra-container, systemd and root privileges
nix run .#tests.default.container
# Run a command in a container
nix run .#tests.default.container -- --run c systemctl status mempool

# Use the following cmds on NixOS with `system.stateVersion` <22.05
nix run .#tests.default.containerLegacy
nix run .#tests.default.containerLegacy -- --run c systemctl status mempool

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Run containers
# This requires that `run-tests.sh` from a nix-bitcoin repo checkout is in PATH.
# Also requires extra-container, systemd and root privileges

# >
bin=$(realpath ./bin) && [[ ":$PATH:" == *":$bin:"* ]] || PATH=$bin:$PATH

run-tests-mempool -s regtest container
run-tests-mempool -s default container
run-tests-mempool -s netnsRegtest container

c systemctl status mempool
c journalctl -u mempool

c systemctl status restart-mempool.timer
c journalctl -u restart-mempool

c systemctl status
c systemctl status electrs
c systemctl status mysql

c systemd-analyze critical-chain

c netstat -nltp

## Run these in scenario `regtest`

# Check backend
c curl -fsS localhost:8999/api/v1/blocks/1 | jq
c curl -fsS localhost:8999/api/v1/blocks/tip/height | jq
c curl -fsS localhost:8999/api/v1/address/1CGG9qVq2P6F7fo6sZExvNq99Jv2GDpaLE | jq

# Check frontend
c curl -fsS localhost:60845
c curl -fsS localhost:60845/api/mempool | jq
c curl -fsS localhost:60845/api/blocks/1 | jq
c curl -fsS localhost:60845/api/v1/blocks/1 | jq
c curl -fsS localhost:60845/api/blocks/tip/height | jq
