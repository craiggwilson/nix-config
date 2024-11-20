{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.pciutils;
in
{
  options.hdwlinux.programs.pciutils = {
    enable = lib.hdwlinux.mkEnableTagsOpt "pciutils" [ "cli" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.pciutils ];
  };
}
