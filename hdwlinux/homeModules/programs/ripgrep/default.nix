{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.ripgrep;
in
{
  options.hdwlinux.programs.ripgrep = {
    enable = lib.hdwlinux.mkEnableOption "ripgrep" true;
  };

  config = lib.mkIf cfg.enable {
    programs.ripgrep = {
      enable = true;
    };
  };
}
