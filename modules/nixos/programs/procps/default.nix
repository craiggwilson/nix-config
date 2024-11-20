{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.procps;
in
{
  options.hdwlinux.programs.procps = {
    enable = lib.hdwlinux.mkEnableTagsOpt "procsps" [ "cli" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.procps ];
  };
}
