{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.libnotify;
in
{
  options.hdwlinux.packages.libnotify = with types; {
    enable = mkBoolOpt false "Whether or not to enable libnotify.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ 
        libnotify
    ];
  };
}
