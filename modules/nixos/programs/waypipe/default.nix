{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.waypipe;
in
{
  options.hdwlinux.programs.waypipe = {
    enable = lib.hdwlinux.mkEnableTagsOpt "waypipe" [ "desktop:remote" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.waypipe
      pkgs.xorg.xauth
    ];
  };
}
