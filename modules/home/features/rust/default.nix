{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.rust;
in
{
  options.hdwlinux.features.rust = with types; {
    enable = mkEnableOpt ["programming"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      cargo
      cmake
      gcc
      gnumake
      pkg-config
      rustc
      rustfmt
    ];

    home.file.".cargo/config".text = ''
      [net]
      git-fetch-with-cli = true
    '';
  };
}
