{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.fonts;
  nf = (
    pkgs.nerdfonts.override {
      fonts = [
        "FiraCode"
        "DroidSansMono"
        "DejaVuSansMono"
      ];
    }
  );
in
{
  options.hdwlinux.fonts = {
    enable = config.lib.hdwlinux.mkEnableOption "fonts" "gui";
  };

  config.fonts = lib.mkIf cfg.enable {
    packages = [
      nf
      pkgs.noto-fonts-emoji
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
