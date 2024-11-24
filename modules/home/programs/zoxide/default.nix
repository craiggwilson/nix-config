{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.zoxide;
in
{
  options.hdwlinux.programs.zoxide = {
    enable = lib.hdwlinux.mkEnableOption "zoxide" true;
  };

  config.programs.zoxide = lib.mkIf cfg.enable {
    enable = true;
    enableBashIntegration = config.hdwlinux.features.bash.enable;
  };
}
