{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.hdwlinux.networking;
in
{
  options.hdwlinux.networking = {
    enable = lib.hdwlinux.mkEnableOpt [ "networking" ] config.hdwlinux.features.tags;
    domain = lib.mkOption {
      type = lib.types.str;
      default = "raeford.wilsonfamilyhq.com";
    };
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
  };
}
