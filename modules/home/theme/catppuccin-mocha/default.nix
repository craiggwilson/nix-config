{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.theme.catppuccin-mocha; 
  wallpaper = ./assets/cat-waves.png;
in {

  options.hdwlinux.theme.catppuccin-mocha = with types; {
    enable = mkBoolOpt false "Whether or not to enable the catppuccin-mocha theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.theme = {
      enable = mkDefault true;
      colors = inputs.themes.catppuccin-mocha;
      wallpapers = [ wallpaper ];
    };

    hdwlinux.features.vscode.theme = "Catppuccin Mocha";
  };
}
