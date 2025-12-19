{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.bandwhich;
in
{
  options.hdwlinux.programs.bandwhich = {
    enable = lib.hdwlinux.mkEnableOption "bandwhich" false;
  };

  config = lib.mkIf cfg.enable {
    programs.bandwhich = {
      enable = true;
    };
  };
}
