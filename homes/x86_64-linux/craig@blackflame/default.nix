{
  lib,
  pkgs,
  inputs,
  config,
  flake,
  ...
}:
{
  imports = [ ../../../users/homes/craig ];

  hdwlinux = {
    theme.catppuccin.enable = true;

    features.lan-mouse = {
      enable = true;
      client = {
        direction = "right";
        hostname = "unsouled";
        ips = [ "192.168.10.53" ];
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  home.stateVersion = "23.05";
}
