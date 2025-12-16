{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./disko.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_6_17;

  hdwlinux = {
    flake = "/home/craig/Projects/github.com/craiggwilson/nix-config";
    hardware.models.dell-xps-15-9520.enable = true;
    tags = [
      "audio"
      "bluetooth"
      "boot:systemd"
      "desktop:hyprland"
      "desktop:niri"
      "desktop:remote"
      "fonts"
      "gui"
      "networking"
      "networking:tailscale"
      "programming"
      "printing"
      "raeford"
      "scanning"
      "security:passwordmanager"
      "users:craig"
      "v4l2loopback"
      "video:production"
      "virtualization:docker"
      "work"
    ];

    hardware = {
      fingerprint.enable = false;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
