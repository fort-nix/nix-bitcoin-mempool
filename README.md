[Mempool](https://github.com/mempool/mempool) module for [nix-bitcoin](https://github.com/fort-nix/nix-bitcoin).

Mempool is a fully featured Bitcoin visualizer, explorer and API service.

## Note

Mempool currently [has a bug](https://github.com/mempool/mempool/issues/2246) where
the Mempool backend stops serving Electrum server requests (like address queries)
after running for 20-30 days.

As a workaround, this module contains a helper service that auto-restarts the backend
after one week.\
This is configurable via option `mempool.autoRestartInterval`.\
Sample values: `5 days`, `1 week` (default), `null` (to disable restarting).

As soon as the bug is fixed, this module will be added to nix-bitcoin.

## Install

1. Import the mempool module in your nix-bitcoin config.

   - If you use flakes, add this flake to your system `flake.nix`:
     ```nix
     {
       inputs.nix-bitcoin.url = "github:fort-nix/nix-bitcoin/release";
       inputs.nix-bitcoin-mempool = {
         url = "github:fort-nix/nix-bitcoin-mempool/release";
         inputs.nix-bitcoin.follows = "nix-bitcoin";
       };

       outputs = { self, nix-bitcoin, nix-bitcoin-mempool, ... }: {
         nixosConfigurations.mynode = nixpkgs.lib.nixosSystem {
           modules = [
             nix-bitcoin.nixosModules.default
             nix-bitcoin-mempool.nixosModules.default
             # ...
           ];
         };
       };
     }

     ```
   - In a non-flakes config::
     ```nix
     {
       imports = [
         (import (builtins.fetchTarball {
           # FIXME:
           # Replace `<SHA1>` in `url` below.
           # You can fetch the release SHA1 like so:
           # curl -fsS https://api.github.com/repos/fort-nix/nix-bitcoin-mempool/git/refs/heads/release | jq -r .object.sha
           url = "https://github.com/fort-nix/nix-bitcoin-mempool/archive/<SHA1>.tar.gz";
           # FIXME:
           # Add hash.
           # The hash is automatically shown when you evaluate your config.
           sha256 = "";
         })).nixosModules.default
       ];
       # ...
     }

     ```

2. Edit your NixOS configuration

   Enable Mempool:
   ```nix
   services.mempool.enable = true;
   ```

   There are two Electrum backend servers you can use:

    - `electrs` (enabled by default):\
      Small database size, slow when querying new addresses.

    - `fulcrum`:\
      Large database size, quickly serves arbitrary address queries.\
      Enable with:
      ```nix
      services.mempool.electrumServer = "fulcrum";
      ```

    Set this to create an onion service to make the Mempool web interface
    available via Tor:
    ```nix
    nix-bitcoin.onionServices.mempool-frontend.enable = true;

    ```
    Set this to route all outgoing internet requests from the backend
    (e.g. rate fetching) through Tor:
    ```nix
    services.mempool.tor = {
      proxy = true;
      enforce = true;
    };
    ```
    Make sure to set the above when using the `secure-node.nix` template.

    See [modules/mempool.nix](./modules/mempool.nix) for all available options.

    After deploying, run `nodeinfo` to show the Mempool web interface address.

## Developing

Run all tests:
```sh
nix flake check
```

See also: [dev/dev.sh](./dev/dev.sh).
