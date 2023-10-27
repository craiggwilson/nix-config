{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.fonts;
  nf = (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "DejaVuSansMono" ]; });
in
{
  options.hdwlinux.features.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to enable fonts.";
  };

  config.fonts = mkIf cfg.enable {
    packages = with pkgs; [
      nf
      noto-fonts-emoji
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [ "FireCode Nerd Font Mono" ];
        sansSerif = [ "FireCode Nerd Font" ];
        serif = [ "FireCode Nerd Font" ];
      };
    };
  };
}
