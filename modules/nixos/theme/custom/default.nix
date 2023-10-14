{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.theme.custom; 
  theme = "${pkgs.base16-schemes}/share/themes/evenok-dark.yaml";
  wallpaper = pkgs.runCommand "image.png" {} ''
    COLOR1=$(${pkgs.yq}/bin/yq -r .base01 ${theme})
    COLOR2=$(${pkgs.yq}/bin/yq -r .base0B ${theme})
    COLOR1="#"$COLOR1
    COLOR2="#"$COLOR2
    ${pkgs.imagemagick}/bin/magick convert -size 2560x1440 gradient:$COLOR1-$COLOR2 -swirl 180 $out
  '';
in {

  options.hdwlinux.theme.custom = with types; {
    enable = mkBoolOpt false "Whether or not to enable the custom theme.";
  };

  config = mkIf cfg.enable {
    # hdwlinux.home.packages = with pkgs; [
    #   imagemagick
    # ];

    hdwlinux.theme.wallpaper1 = wallpaper;
    hdwlinux.theme.wallpaper2 = wallpaper;
    hdwlinux.theme.wallpaper3 = wallpaper;

    stylix = {
      base16Scheme = theme;
    };
  };
}