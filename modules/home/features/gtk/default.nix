{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.gtk;
in
{
  options.hdwlinux.features.gtk = with types; {
    enable = mkEnableOpt ["gui"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    gtk =  {
      enable = true;

      gtk3 = mkIf config.hdwlinux.theme.enable {
        extraConfig = {
          gtk-application-prefer-dark-theme = config.hdwlinux.theme.dark;
        };
        extraCss = mkIf (config.gtk.theme == null) config.hdwlinux.theme.colors.adwaitaGtkCss;
      };
      gtk4 = mkIf config.hdwlinux.theme.enable {
        extraConfig = {
          gtk-application-prefer-dark-theme = config.hdwlinux.theme.dark;
        };
        extraCss = mkIf (config.gtk.theme == null) config.hdwlinux.theme.colors.adwaitaGtkCss;
      };
    };
  };
}
