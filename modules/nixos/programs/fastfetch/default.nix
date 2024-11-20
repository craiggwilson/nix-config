{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.fastfetch;
in
{
  options.hdwlinux.programs.fastfetch = {
    enable = lib.hdwlinux.mkEnableTagsOpt "fastfetch" [ "cli" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.fastfetch
    ];
  };
}
