{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.theme.ayu-dark; 
  theme = "${pkgs.base16-schemes}/share/themes/ayu-dark.yaml";
  wallpaper = ./assets/bubbles.jpg;
in {

  options.hdwlinux.theme.ayu-dark = with types; {
    enable = mkBoolOpt false "Whether or not to enable the ayu-dark theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.theme.wallpaper1 = wallpaper;
    hdwlinux.theme.wallpaper2 = wallpaper;
    hdwlinux.theme.wallpaper3 = wallpaper;

    stylix.base16Scheme = theme;
  };
}
