{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.steam;
in
{
  options.hdwlinux.programs.steam = {
    enable = config.lib.hdwlinux.mkEnableAllOption "steam" [
      "gui"
      "gaming"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.steam.override {
        extraPkgs = pkgs: [
          pkgs.xorg.libXcursor
          pkgs.xorg.libXi
          pkgs.xorg.libXinerama
          pkgs.xorg.libXScrnSaver
          pkgs.libpng
          pkgs.libpulseaudio
          pkgs.libvorbis
          pkgs.stdenv.cc.cc.lib
          pkgs.libkrb5
          pkgs.keyutils
        ];
      })
    ];
  };
}
