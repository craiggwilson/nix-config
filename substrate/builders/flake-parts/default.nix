{
  build =
    args@{
      inputs,
      flake-parts-lib ? inputs.flake-parts.lib,
      ...
    }:
    module:
    flake-parts-lib.mkFlake args {
      imports = [
        ./adapter.nix
        module
      ];
    };
}
