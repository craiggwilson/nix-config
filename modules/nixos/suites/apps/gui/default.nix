{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.gui;
in
{
  options.hdwlinux.suites.apps.gui = with types; {
    enable = mkBoolOpt false "Whether or not to enable the graphical apps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.packages = {
      _1password.enable = true;
      calibre.enable = true;
      fonts.enable = true;
      firefox.enable = true;
      gimp.enable = true;
      kitty.enable = true;
      libreoffice.enable = true;
      musescore.enable = true;
    };
  };
}
