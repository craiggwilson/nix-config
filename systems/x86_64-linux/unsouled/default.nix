{ inputs
, config
, lib
, pkgs
, ...
}:
{
  imports = [
    ../../../hardware/dell-xps-15-9520.nix
    ./disko.nix
    ../../../users/nixos/craig
  ];


  hdwlinux = {
    nix = {
      enable = true;
      flake = "/home/craig/Projects/github.com/craiggwilson/nix-config";
    };

    features = {
      tags = [
        "ai"
        "audio:production"
        "cli"
        "gui"
        "desktop:hyprland"
        "displayManager:greetd"
        "filesystem:nfs"
        "fonts"
        "gaming"
        "programming"
        "printing"
        "service"
        "virtualization:docker"
        "work"
      ];

      displayManager.greetd.startCommand = "dbus-run-session Hyprland";
      nfs.mounts = [
        {
          local = "/mnt/games";
          remote = "synology.raeford.wilsonfamilyhq.com:/volume2/games";
          auto = true;
        }
      ];
      printing.raeford = true;
      tailscale = {
        enable = true;
        exitNode = "synology";
      };
    };
  };

  home-manager = {
    sharedModules = [
      {
        hdwlinux.features = {
          monitors.monitors = [
            {
              name = "eDP-1";
              workspace = "1";
              width = 1920;
              height = 1200;
              x = 0;
              y = 0;
              scale = 1;
            }
            {
              name = "DP-5";
              workspace = "2";
              width = 2560;
              height = 1440;
              x = 0;
              y = -1440;
              scale = 1;
            }
            {
              name = "DP-6";
              workspace = "3";
              width = 2560;
              height = 1440;
              x = 2560;
              y = -1440;
              scale = 1;
            }
          ];
          tags = config.hdwlinux.features.tags;
        };
      }
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
