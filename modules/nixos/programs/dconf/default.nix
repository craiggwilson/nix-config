{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.dconf;
in
{
  options.hdwlinux.programs.dconf = {
    enable = lib.hdwlinux.mkEnableOption "dconf" true;
  };

  config = lib.mkIf cfg.enable {
    programs.dconf.enable = true;
  };
}
