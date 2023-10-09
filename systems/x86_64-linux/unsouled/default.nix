{ inputs, ... }: {
  imports = [
    ../../../hardware/dell-xps-15-9520.nix
    ./disko.nix

    ../../../users/craig
  ];

  time.timeZone = "America/Chicago";

  hdwlinux = {
    nix.enable = true;

    packages.openssh.enable = true;

    suites = {
      boot.systemd.enable = true;
      #displayManager.gdm.enable = true;
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
