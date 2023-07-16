{ scenarios, ... }:
let
  nbScenarios = scenarios;
  flake = builtins.getFlake "git+file://${toString ./..}";
  tests = import ./../test/tests.nix flake;
in
tests.scenarios // {

  regtest = {
    imports = [
      tests.scenarios.default
      nbScenarios.regtestBase
    ];
    nix-bitcoin.nodeinfo.enable = true;
  };
}
