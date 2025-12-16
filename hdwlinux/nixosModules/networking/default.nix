{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.networking;
in
{
  options.hdwlinux.networking = {
    enable = config.lib.hdwlinux.mkEnableOption "networking" "networking";
    domain = lib.hdwlinux.sharedOptions.networking.domain;
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager = {
        enable = true;
        wifi.backend = "iwd";
      };
      useDHCP = lib.mkDefault true;

      firewall = {
        enable = true;
      };
    };

    home-manager.sharedModules = [
      {
        hdwlinux.networking.domain = cfg.domain;
      }
    ];
  };
}
