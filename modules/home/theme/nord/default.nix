{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.theme.nord; 
  theme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
  wallpaper = ./assets/wild.png;
in {

  options.hdwlinux.theme.nord = with types; {
    enable = mkBoolOpt false "Whether or not to enable the nord theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.theme.wallpapers = [ wallpaper ];

    stylix.base16Scheme = theme;
  };
}