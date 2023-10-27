{ inputs, config, lib, pkgs, ... }: {
  imports = [
    ../../../hardware/dell-xps-15-9520.nix
    ./disko.nix
    ./users.nix
  ];

  time.timeZone = "America/Chicago";

  hdwlinux = {
    nix = {
      enable = true;
      flake = "/home/craig/Projects/github.com/craiggwilson/nix-config";
    };

    features = {
      hyprland.enable = true;
      printing.enable = true;
      mongodb.enable = true;
    };

    suites = {
      boot.systemd.enable = true;
      displayManagers.greetd.enable = true;

      apps.cli.core.enable = true;
      apps.gui.core.enable = true;
      services.core.enable = true;
    };
  };

  home-manager = {
    extraSpecialArgs = {
      flake = config.hdwlinux.nix.flake;
    };

    sharedModules = [
      {
        hdwlinux.features.monitors.monitors = [
          { 
            name = "eDP-1"; 
            workspace = "1";
            width = 1920;
            height = 1200;
            x = 0;
            y = 1440;
            scale = 1;
          }
          { 
            name = "DP-5"; 
            workspace = "2";
            width = 2560;
            height = 1440;
            x = 0;
            y = 0;
            scale = 1;
          }
          { 
            name = "DP-6"; 
            workspace = "3";
            width = 2560;
            height = 1440;
            x = 2560;
            y = 0;
            scale = 1;
          }
        ];
      }
    ];
  };

  hardware = {
    printers = lib.mkIf config.hdwlinux.features.printing.enable {
      ensurePrinters = [
        {
          name = "Brother_HL-L2380DW";
          location = "Raeford";
          deviceUri = "https://printer.raeford.wilsonfamilyhq.com";
          model = "drv:///sample.drv/generic.ppd";
        }
      ];
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
