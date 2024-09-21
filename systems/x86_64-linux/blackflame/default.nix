{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../../hardware/system76-serval-ws.nix
    ./disko.nix
    ../../../users/nixos/craig
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_6_10;
  };

  hdwlinux = {
    nix = {
      enable = true;
      flake = "/home/craig/Projects/github.com/craiggwilson/nix-config";
    };

    features = {
      tags = [
        "av"
        "cli"
        "gui"
        "desktop:hyprland"
        "filesystem:nfs"
        "fonts"
        "gaming"
        "personal"
        "programming"
        "printing"
        "scanning"
        "virtualization:podman"
        "vnc"
      ];

      fingerprint.enable = false; # hardware has it, but it doesn't work great.

      nfs.mounts = [
        {
          local = "/mnt/games";
          remote = "synology.raeford.wilsonfamilyhq.com:/volume2/games";
          auto = true;
        }
      ];
      printing.raeford = true;
      scanning.raeford = true;
      tailscale = {
        enable = true;
        exitNode = "synology";
      };
    };

    monitors = [
      {
        port = "eDP-1";
        width = 1920;
        height = 1080;
        x = 0;
        y = 1440;
        scale = 1;
      }
      {
        description = "Dell Inc. DELL S2721DGF 2WXSR83";
        workspace = "2";
        width = 2560;
        height = 1440;
        x = 0;
        y = 0;
        scale = 1;
      }
      {
        description = "Dell Inc. DELL S2721DGF DSWSR83";
        workspace = "3";
        width = 2560;
        height = 1440;
        x = 2560;
        y = 0;
        scale = 1;
      }
      {
        description = "Ancor Communications Inc MB169B+       AIC1643";
        workspace = "1";
        width = 1920;
        height = 1080;
        x = 1920;
        y = 1440;
        scale = 1;
        displaylink = true;
      }
    ];
  };

  # boot.resumeDevice = "/dev/disk/by-uuid/451cd5d5-024b-4c13-9914-db4d4ab6c8db"; # findmnt -no UUID -T /.swapvol/swapfile
  # boot.kernelParams = [
  #   "resume_offset=533760" # btrfs inspect-internal map-swapfile -r /.swapvol/swapfile
  # ];
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
