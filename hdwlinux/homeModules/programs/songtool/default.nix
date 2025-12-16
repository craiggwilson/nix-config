{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.programs.songtool;
in
{
  options.hdwlinux.programs.songtool = {
    enable = lib.hdwlinux.mkEnableOption "songtool" true;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [ hdwlinux.songtool ];
}
