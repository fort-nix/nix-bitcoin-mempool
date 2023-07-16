{
  inputs.nix-bitcoin.url = "github:erikarvstedt/nix-bitcoin/nixos-23.05";

  outputs = { self, nix-bitcoin }: let
    inherit (nix-bitcoin.inputs)
      nixpkgs
      flake-utils;

    makePkgs = pkgs: nbPkgs: {
      inherit (pkgs.callPackage ./pkgs/mempool { inherit (nbPkgs) fetchNodeModules; })
        mempool-backend
        mempool-frontend
        mempool-nginx-conf;
    };

    tests = import ./test/tests.nix self;
  in {
    lib = {
      inherit (tests) scenarios;
      inherit nix-bitcoin;
    };

    nixosModules.default = { pkgs, ... }: {
      imports = [ ./modules/mempool.nix ];

      nix-bitcoin.pkgOverlays = (super: self:
        makePkgs self.pinned.pkgs self
      );
    };
  }
  // (flake-utils.lib.eachSystem nix-bitcoin.lib.supportedSystems (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = makePkgs pkgs nix-bitcoin.legacyPackages.${system};

      legacyPackages = tests.pkgs system;

      checks = self.legacyPackages.${system}.tests;
    }
  ));
}
