{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
let
  cfg = config.hdwlinux.features.networking;
in
{
  options.hdwlinux.features.networking = {
    enable = lib.hdwlinux.mkEnableOpt [ "networking" ] config.hdwlinux.features.tags;
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
        checkReversePath = lib.mkIf config.hdwlinux.features.tailscale.enable "loose";
      };
    };

    environment.systemPackages = [ pkgs.networkmanager-l2tp ];
  };
}
