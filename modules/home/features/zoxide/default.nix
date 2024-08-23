{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.zoxide;
in
{
  options.hdwlinux.features.zoxide = with types; {
    enable = mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config.programs.zoxide = mkIf cfg.enable {
    enable = true;
    enableBashIntegration = config.hdwlinux.features.bash.enable;
  };
}
