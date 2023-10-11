{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.firefox;
in
{
  options.hdwlinux.packages.firefox = with types; {
    enable = mkBoolOpt false "Whether or not to enable firefox.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.firefox.enable = true;

    xdg.mime.defaultApplications."application/pdf" = "firefox.desktop";
  };
}
