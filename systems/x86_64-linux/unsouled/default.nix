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

    features = {
      # printing = {
      #   enable = true;
      #   brother.laser.enable = true;
      # };

      # scanning.enable = true;
    };

    features.hyprland.enable = true;
    features.mongodb.enable = true;

    suites = {
      boot.systemd.enable = true;
      displayManagers.greetd.enable = true;

      apps.cli.core.enable = true;
      apps.gui.core.enable = true;
      services.core.enable = true;
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
