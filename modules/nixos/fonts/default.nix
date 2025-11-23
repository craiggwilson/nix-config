{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.fonts;
in
{
  options.hdwlinux.fonts = {
    enable = config.lib.hdwlinux.mkEnableOption "fonts" "gui";
  };

  config.fonts = lib.mkIf cfg.enable {
    packages = [
      pkgs.nerd-fonts.droid-sans-mono
      pkgs.nerd-fonts.dejavu-sans-mono
      pkgs.nerd-fonts.fira-code
      pkgs.noto-fonts-color-emoji
      pkgs.comic-mono
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
