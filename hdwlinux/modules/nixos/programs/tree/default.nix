{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.tree;
in
{
  options.hdwlinux.programs.tree = {
    enable = lib.hdwlinux.mkEnableOption "tree" true;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tree ];
  };
}
