{ options, config, pkgs, lib, host ? "", format ? "", inputs ? { }, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.home-manager;
in
{
  options.hdwlinux.features.home-manager = with types; {
    enable = mkBoolOpt true "Whether or not to configure home-manager.";
  };

  config = mkIf cfg.enable {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };
  };
}
