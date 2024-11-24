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

  config = lib.mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableBashIntegration = config.hdwlinux.features.bash.enable;
    };
  };
}
