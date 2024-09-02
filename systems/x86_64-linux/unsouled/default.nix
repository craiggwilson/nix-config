{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../../hardware/dell-xps-15-9520.nix
    ./disko.nix
    ../../../users/nixos/craig
  ];

  hdwlinux = {
    nix.flake = "/home/craig/Projects/github.com/craiggwilson/nix-config";

    features = {
      tags = [
        "av"
        "cli"
        "gui"
        "desktop:hyprland"
        "fonts"
        "gaming"
        "personal"
        "programming"
        "printing"
        "virtualization:docker"
        "work"
      ];

      #displaylink.enable = true;
      fstrim.enable = false;

      printing.raeford = true;
      tailscale = {
        enable = true;
        exitNode = "synology";
      };
    };

    monitors = [
      {
        port = "eDP-1";
        workspace = "1";
        width = 1920;
        height = 1200;
        x = 0;
        y = 0;
        scale = 1;
      }
      {
        description = "Dell Inc. DELL S2721DGF 2WXSR83";
        workspace = "2";
        width = 2560;
        height = 1440;
        x = 0;
        y = -1440;
        scale = 1;
      }
      {
        description = "Dell Inc. DELL S2721DGF DSWSR83";
        workspace = "3";
        width = 2560;
        height = 1440;
        x = 2560;
        y = -1440;
        scale = 1;
      }
    ];
  };

  boot.resumeDevice = "/dev/disk/by-uuid/451cd5d5-024b-4c13-9914-db4d4ab6c8db"; # findmnt -no UUID -T /.swapvol/swapfile
  boot.kernelParams = [
    "resume_offset=533760" # btrfs inspect-internal map-swapfile -r /.swapvol/swapfile
  ];
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=60m
    SuspendState=mem # suspend2idle is buggy :(
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
