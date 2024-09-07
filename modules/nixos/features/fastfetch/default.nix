{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.fastfetch;
in
{
  options.hdwlinux.features.fastfetch = {
    enable = lib.hdwlinux.mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config.environment.systemPackages = lib.mkIf cfg.enable [
    pkgs.fastfetch
  ];
}
