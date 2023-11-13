{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.networking; 
in {
  options.hdwlinux.features.networking = with types; {
    enable = mkBoolOpt false "Whether or not to enable networking support.";
    enableL2tpVpn = mkBoolOpt true "Whether or not to enable l2tp vpn support.";
  };

  config = mkIf cfg.enable {
    networking = {
      networkmanager.enable = true;
      useDHCP = lib.mkDefault true;

      firewall.enable = true;

      firewall.checkReversePath = mkIf config.hdwlinux.features.tailscale.enable "loose";
    };

    environment.systemPackages = with pkgs; mkIf cfg.enableL2tpVpn [
      networkmanager-l2tp
    ];
  };
}
