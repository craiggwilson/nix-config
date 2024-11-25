{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.lsd;
in
{
  options.hdwlinux.programs.lsd = {
    enable = lib.hdwlinux.mkEnableOption "lsd" true;
  };

  config = lib.mkIf cfg.enable {
    programs.lsd = {
      enable = true;
      enableAliases = true;
    };
  };
}
