{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.btop;
in
{
  options.hdwlinux.programs.btop = {
    enable = lib.hdwlinux.mkEnableOption "btop" true;
  };

  config = lib.mkIf cfg.enable {
    programs.btop = {
      enable = true;
    };
  };
}
