{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.gui.core;
in
{
  options.hdwlinux.suites.apps.gui.core = with types; {
    enable = mkBoolOpt false "Whether or not to enable the graphical apps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
      calibre.enable = true;
      firefox.enable = true;
      gimp.enable = true;
      kitty.enable = true;
      libreoffice.enable = true;
      logseq.enable = true;
      musescore.enable = true;
      nerdfonts.enable = true;
    };
  };
}
