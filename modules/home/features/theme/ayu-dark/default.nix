{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.theme.ayu-dark; 
  theme = "${pkgs.base16-schemes}/share/themes/ayu-dark.yaml";
  wallpaper = ./assets/bubbles.jpg;
in {

  options.hdwlinux.features.theme.ayu-dark = with types; {
    enable = mkBoolOpt false "Whether or not to enable the ayu-dark theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features.theme.wallpapers = [ wallpaper ];

    stylix.base16Scheme = theme;
  };
}
