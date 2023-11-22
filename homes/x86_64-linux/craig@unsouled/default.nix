{ lib, pkgs, inputs, config, flake, ... }:
let
  privatePath = ../../../private/craig/default.nix;
in {
  imports = lib.optional (builtins.pathExists privatePath) privatePath;

  hdwlinux = {
    theme.ayu-dark.enable = true;

    user = {
      fullName = "Craig Wilson";
      email = "craiggwilson@gmail.com";
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL5nMCsw3AQ1HaLzvLGW51yjlKGXGR0ECeEb/WAuIGBdKs+nKo7W40d9cXN/XYH6YWZXhg/mw6RFOP5K7CB1FlVozVOqSvso2GcCUCBacjCXWrnubRUsJ5mHDdsmm3jwYGzaSNjgutVpwtj0+ijwACS5C7/m2QpatSdYFOuQhNk1KhaatoKhwWuOeh5kbpWCwUZTtTwrzphegIFDWgfErWwa0O2LKI1cVsFZkT/SgKkjILDfNJ1sYL98tKPouNrMMZj+5/tV1vxIY3UFsbAY78lZUY1yeHmTdJBjwxtG9P7+Dw4CJf9RjS35eCUA84hw95GRVfGAMj/8VasTnHsstvuNiG58lp8ufbfC8T/wGPNH7LwPmqV0TdD26s2nTikvC0qiy/QU58IeXXahI2/dmaWK+qfCayw3sL2DS/5A+HLl09lpVLLNhChnN//0mvUy0to0rCbFwqFXwmIHlveGlYdkEoRiYD4jnu/aTLfnW6YC3Ew1wVyJRH3QHXIIbWafs7R6owHWhcWEe6/CYEDAq1RTy4dknXR7DTbqhKgPX+1FnG9l9GilAwRlsb1qThHikpj2LcRvj0t0tKNO92guUAFqPyByrN9CGDimefiRqZHXkwPTl0Cr4sq3xfuW9J3wgA0u0yieLQO6EKE8adLzOfrzHEathtg+anUPYg84n2Dw== craiggwilson@gmail.com";
    };

    suites = {
      desktops.hyprland.enable = true;
      shell.bash.enable = true;
      apps = {
        cli = {
          core.enable = true;
          programming.enable = true;
          work.enable = true;
        };
        gui = {  
          core.enable = true;
          gaming.enable = true;
          programming.enable = true;
          work.enable = true;
        };
      };
      services = {
        core.enable = true;
        gui.enable = true;
      };
    };

    features = {
      simplescan.enable = true;
    };
  };

  home.sessionVariables = {
    NIX_CONFIG_FLAKE=flake;
  };

  home.shellAliases = {
    "start" = "xdg-open";
    "nix-config" = "git -C ${flake}";
    "nix-config-switch" = "nix-config add -A . && sudo nixos-rebuild switch --flake ${flake}?submodules=1";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  home.stateVersion = "23.05";
}
