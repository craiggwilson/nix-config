{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.micro;
in
{
  options.hdwlinux.packages.micro = with types; {
    enable = mkBoolOpt false "Whether or not to enable dunst.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.micro = {
      enable = true;
      settings = {
        mkparents = true;
      };
    };

    hdwlinux.home.sessionVariables = {
      EDITOR = "micro";
      VISUAL = "micro";
    };
  };
}
