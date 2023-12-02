{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.theme.ayu-dark; 
  wallpaper = ./assets/bubbles.jpg;
in {

  options.hdwlinux.theme.ayu-dark = with types; {
    enable = mkBoolOpt false "Whether or not to enable the ayu-dark theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.theme = {
      colors = inputs.themes.ayu-dark;
      wallpapers = [ wallpaper ];
    };
  };
}
