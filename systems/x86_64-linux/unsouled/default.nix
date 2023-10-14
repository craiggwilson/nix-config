{ inputs, config, lib, ... }: 
{
  imports = [
    ../../../hardware/dell-xps-15-9520.nix
    ./disko.nix
  ] ++ lib.optional (builtins.pathExists ../../../private/craig/default.nix) ../../../private/craig;

  time.timeZone = "America/Chicago";

  hdwlinux = {
    nix = {
      enable = true;
      flake = "/home/craig/Projects/github.com/craiggwilson/nix-config";
    };

    theme.nord.enable = true;

    packages = {
      hyprland.settings = {
        monitor = [
          "DP-5, 2560x1440, 0x0, 1"
          "DP-6, 2560x1440, 2560x0, 1"
          "eDP-1, highres, 0x1440, 1"
          ", preferred, auto, auto"
        ];

        workspace = [
          "1, monitor:eDP-1"
          "2, monitor:DP-5"
          "3, monitor:DP-6"
        ];
      };

      hyprpaper = {
        monitors = [
          { name = "eDP-1"; wallpaper = config.hdwlinux.theme.wallpaper1; }
          { name = "DP-5"; wallpaper = config.hdwlinux.theme.wallpaper2; }
          { name = "DP-6"; wallpaper = config.hdwlinux.theme.wallpaper3; }
        ];
      };

      openssh.enable = true;
    };

    suites = {
      boot.systemd.enable = true;
      displayManagers.greetd.enable = true;
      desktops.hyprland.enable = true;
      shell.bash.enable = true;

      apps.cli.enable = true;
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
