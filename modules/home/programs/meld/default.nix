{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.meld;
in
{
  options.hdwlinux.programs.meld = {
    enable = lib.hdwlinux.mkEnableOption "meld" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.meld ];
  };
}
