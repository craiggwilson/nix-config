{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs._1password-cli;
in
{
  options.hdwlinux.programs._1password-cli = {
    enable = config.lib.hdwlinux.mkEnableOption "1password-cli" "security:passwordmanager";
  };

  config = lib.mkIf cfg.enable {
    programs._1password.enable = true;
  };
}
