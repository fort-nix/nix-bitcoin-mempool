flake:
let
  inherit (flake.inputs) nix-bitcoin;

  nbScenarios = nix-bitcoin.lib.test.scenarios;

  scenarios = {
    default = { config, ... }: {
      imports = [ flake.nixosModules.default ];

      tests.mempool = config.services.mempool.enable;
      services.mempool.enable = true;

      test.extraTestScript = builtins.readFile ./tests.py;
    };

    netnsRegtest = {
      imports = [
        scenarios.default
        nbScenarios.regtestBase
        nbScenarios.netnsBase
      ];

      nix-bitcoin.nodeinfo.enable = true;
    };
  };

in {
  inherit scenarios;

  pkgs = system: let
    inherit (nix-bitcoin.legacyPackages.${system}) makeTest;
  in {
    tests = {
      default = makeTest {
        name = "mempool-default";
        config = {
          imports = [ scenarios.default ];
          # Run shellcheck on all services defined by this flake
          test.shellcheckServices.sourcePrefix = toString ./..;
        };
      };

      netnsRegtest = makeTest {
        name = "mempool-netns-regtest";
        config = scenarios.netnsRegtest;

        # Don't run shellcheck here because it fails with an error
        # ("no services are detected").
        # Reason:
        # Only services that are exclusively defined in files with `sourcePrefix`
        # are detected, but in this scenario the mempool service is also defined
        # by file `netns-isolation.nix` in nix-bitcoin.
      };
    };
  };
}
