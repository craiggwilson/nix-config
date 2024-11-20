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
    enable = lib.hdwlinux.mkEnableTagsOpt "1password-cli" [ "cli" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    programs._1password.enable = true;
  };
}
