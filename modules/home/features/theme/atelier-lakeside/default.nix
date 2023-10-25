{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.theme.atelier-lakeside; 
  theme = "${pkgs.base16-schemes}/share/themes/atelier-lakeside.yaml";
  wallpaper = ./assets/lake.jpg;
in {

  options.hdwlinux.features.theme.atelier-lakeside = with types; {
    enable = mkBoolOpt false "Whether or not to enable the atelier-lakeside theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features.theme.wallpapers = [ wallpaper ];

    stylix = {
      base16Scheme = theme;
    };
  };
}