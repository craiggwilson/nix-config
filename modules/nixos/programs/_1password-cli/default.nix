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
    enable = lib.mkOption {
      description = "Whether to enable the 1password-cli.";
      type = lib.types.bool;
      default = config.hdwlinux.security.passwordmanager.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    programs._1password.enable = true;
  };
}
