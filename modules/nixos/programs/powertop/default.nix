{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.powertop;
in
{
  options.hdwlinux.programs.powertop = {
    enable = lib.hdwlinux.mkEnableTagsOpt "powertop" [ "cli" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.powertop ];
  };
}
