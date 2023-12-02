{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.theme.nord; 
  wallpaper = ./assets/wild.png;
in {

  options.hdwlinux.theme.nord = with types; {
    enable = mkBoolOpt false "Whether or not to enable the nord theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.theme = {
      colors = inputs.themes.nord;
      wallpapers = [ wallpaper ];
    };
  };
}
