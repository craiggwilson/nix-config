{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.networkmanagerapplet;
in
{
  options.hdwlinux.packages.networkmanagerapplet = with types; {
    enable = mkBoolOpt false "Whether or not to enable networkmanagerapplet.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ 
        networkmanagerapplet
    ];
  };
}
