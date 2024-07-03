{ config, lib, pkgs, ... }:

let cfg = config.hdwlinux.features.steam;
in
{
  options.hdwlinux.features.steam = {
    enable = lib.hdwlinux.mkEnableOpt [ "gui" "gaming" ] config.hdwlinux.features.tags;
  };

  config.home.packages = lib.mkIf cfg.enable [
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
}
