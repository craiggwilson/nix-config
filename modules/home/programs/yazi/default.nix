{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.yazi;
in
{
  options.hdwlinux.programs.yazi = {
    enable = lib.hdwlinux.mkEnableOption "yazi" true;
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
    };
  };
}
