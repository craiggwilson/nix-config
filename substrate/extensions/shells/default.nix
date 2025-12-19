{ lib, ... }:
{
  options.substrate.settings = {
    shells = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = "List of paths to shell definitions (nix files that return a function taking pkgs and returning a derivation).";
      default = [ ];
    };
  };
}
