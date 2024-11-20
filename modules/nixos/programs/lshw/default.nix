{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.lshw;
in
{
  options.hdwlinux.programs.lshw = {
    enable = lib.hdwlinux.mkEnableTagsOpt "lshw" [ "cli" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.lshw ];
  };
}
