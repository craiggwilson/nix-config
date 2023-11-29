{ lib, pkgs, inputs, config, flake, ... }: 
{
  imports = [
    ../../../users/homes/craig
  ];

  hdwlinux = {
    theme.ayu-dark.enable = true;

    suites = {
      desktops.hyprland.enable = true;
      shell.bash.enable = true;
      apps = {
        cli = {
          core.enable = true;
          programming.enable = true;
        };
        gui = {  
          core.enable = true;
          gaming.enable = true;
          programming.enable = true;
        };
      };
      services = {
        core.enable = true;
        gui.enable = true;
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  home.stateVersion = "23.05";
}
