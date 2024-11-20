{
  options,
  config,
  pkgs,
  lib,
  host ? "",
  format ? "",
  inputs ? { },
  ...
}:

let
  cfg = config.hdwlinux.features.home-manager;
in
{
  options.hdwlinux.features.home-manager = {
    enable = lib.hdwlinux.mkBoolOpt true "Whether or not to configure home-manager.";
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };
  };
}
