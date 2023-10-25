{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.libnotify;
in
{
  options.hdwlinux.features.libnotify = with types; {
    enable = mkBoolOpt false "Whether or not to enable libnotify.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    libnotify
  ];
}
