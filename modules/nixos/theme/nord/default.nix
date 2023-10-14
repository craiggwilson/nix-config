{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.theme.nord; 
in {

  options.hdwlinux.theme.nord = with types; {
    enable = mkBoolOpt false "Whether or not to enable the nord theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.theme.wallpaper1 = ./assets/wild.png;
    hdwlinux.theme.wallpaper2 = ./assets/wild.png;
    hdwlinux.theme.wallpaper3 = ./assets/wild.png;

    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
  };
}
