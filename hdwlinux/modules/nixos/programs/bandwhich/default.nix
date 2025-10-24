{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programsd.bandwhich;
in
{
  options.hdwlinux.programsd.bandwhich = {
    enable = lib.hdwlinux.mkEnableOption "bandwhich" true;
  };

  config = lib.mkIf cfg.enable {
    programs.bandwhich = {
      enable = true;
    };
  };
}
