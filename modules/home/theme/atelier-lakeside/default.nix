{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.theme.atelier-lakeside; 
  wallpaper = ./assets/lake.jpg;
in {

  options.hdwlinux.theme.atelier-lakeside = with types; {
    enable = mkBoolOpt false "Whether or not to enable the atelier-lakeside theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.theme = {
      colors = inputs.themes.atelier-lakeside;
      wallpapers = [ wallpaper ];
    };
  };
}