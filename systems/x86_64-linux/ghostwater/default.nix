{ inputs, config, lib, pkgs, ... }: {
  imports = [
    ../../../hardware/microsoft-surface-book-2.nix
    ./disko.nix
    ../../../users/nixos/craig
  ];

  time.timeZone = "America/Chicago";

  hdwlinux = {
    nix = {
      enable = true;
      flake = "/home/craig/Projects/github.com/craiggwilson/nix-config";
    };

    features = {
      tags = ["cli" "gui" "desktop:gnome" "displayManager:gdm" "fonts" "gaming" "printing" "service"];

      printing.raeford = true;
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
            width = 3000;
            height = 2000;
            x = 0;
            y = 0;
            scale = 2;
          }
        ];
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
