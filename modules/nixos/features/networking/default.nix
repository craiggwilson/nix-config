{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.networking; 
in {
  options.hdwlinux.features.networking = with types; {
    enable = mkEnableOpt ["networking"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    networking = {
      networkmanager.enable = true;
      useDHCP = lib.mkDefault true;

      firewall.enable = true;

      firewall.checkReversePath = mkIf config.hdwlinux.features.tailscale.enable "loose";
    };

    environment.systemPackages = with pkgs; [
      networkmanager-l2tp
    ];
  };
}
