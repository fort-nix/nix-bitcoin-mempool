[Mempool](https://github.com/mempool/mempool) is now a core [nix-bitcoin](https://github.com/fort-nix/nix-bitcoin) module.\
This repo is still useful as an example of how to extend nix-bitcoin with Flakes.

# Readme

 [Mempool](https://github.com/mempool/mempool) module for [nix-bitcoin](https://github.com/fort-nix/nix-bitcoin).

Mempool is a fully featured Bitcoin visualizer, explorer and API service.

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
   - In a non-flakes config (i.e., for users of the krops deployment method):\
     Add another entry to `imports` at the top of your `configuration.nix`, like so:
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

         # Your other imports...
       ];

       # The rest of your node config...
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

Dev cmds: [dev/dev.sh](./dev/dev.sh).
