{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.packages.networking; 
in {
  options.hdwlinux.packages.networking = with types; {
    enable = mkBoolOpt false "Whether or not to enable networking support.";
    enableL2tpVpn = mkBoolOpt true "Whether or not to enable l2tp vpn support.";
  };

  config = mkIf cfg.enable {
    hdwlinux.user.extraGroups = [ "networkmanager" ];

    networking = {
      networkmanager.enable = true;
      useDHCP = lib.mkDefault true;

      firewall.enable = true;
    };

    environment.systemPackages = with pkgs; mkIf cfg.enableL2tpVpn [
      networkmanager-l2tp
    ];
  };
}
