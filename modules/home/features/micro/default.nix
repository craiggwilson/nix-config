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
  cfg = config.hdwlinux.features.micro;
in
{
  options.hdwlinux.features.micro = with types; {
    enable = mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    programs.micro = {
      enable = true;
      settings = {
        mkparents = true;
        softwrap = true;
      };
    };

    home.sessionVariables = {
      EDITOR = "micro";
      VISUAL = "micro";
    };
  };
}
