{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.micro;
in
{
  options.hdwlinux.features.micro = with types; {
    enable = mkBoolOpt false "Whether or not to enable dunst.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.micro = {
      enable = true;
      settings = {
        mkparents = true;
        softwrap = true;
      };
    };

    hdwlinux.home.sessionVariables = {
      EDITOR = "micro";
      VISUAL = "micro";
    };
  };
}
