{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.networking;
in
{
  options.hdwlinux.networking = {
    enable = config.lib.hdwlinux.mkEnableOption "networking" "networking";
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
