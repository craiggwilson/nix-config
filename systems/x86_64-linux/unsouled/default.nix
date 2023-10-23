{ inputs, config, lib, ... }: 
{
  imports = [
    ../../../hardware/dell-xps-15-9520.nix
    ./disko.nix
  ]; # ++ lib.optional (builtins.pathExists ../../../private/craig/default.nix) ../../../private/craig;

  time.timeZone = "America/Chicago";

  hdwlinux = {
    nix = {
      enable = true;
      flake = "/home/craig/Projects/github.com/craiggwilson/nix-config";
    };

    theme.ayu-dark.enable = true;

    features = {
      monitors = {
        enable = true;
        monitors = [
          { 
            name = "eDP-1"; 
            workspace = "1";
            width = 1920;
            height = 1200;
            x = 0;
            y = 1440;
            scale = 1;
            wallpaper = config.hdwlinux.theme.wallpaper1; 
          }
          { 
            name = "DP-5"; 
            workspace = "2";
            width = 2560;
            height = 1440;
            x = 0;
            y = 0;
            scale = 1;
            wallpaper = config.hdwlinux.theme.wallpaper1; 
          }
          { 
            name = "DP-6"; 
            workspace = "3";
            width = 2560;
            height = 1440;
            x = 2560;
            y = 0;
            scale = 1;
            wallpaper = config.hdwlinux.theme.wallpaper1; 
          }
        ];
      };

      openssh.enable = true;

      # printing = {
      #   enable = true;
      #   brother.laser.enable = true;
      # };

      # scanning.enable = true;
    };

    suites = {
      boot.systemd.enable = true;
      displayManagers.greetd.enable = true;
      desktops.hyprland.enable = true;

      apps.gaming.enable = true;
      apps.gui.enable = true;
      apps.programming.enable = true;
      apps.tools.enable = true;
      apps.work.enable = true;
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
