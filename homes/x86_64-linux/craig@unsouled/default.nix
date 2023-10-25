{ lib, pkgs, inputs, config, ... }:
{
  imports = [ ]; # ++ lib.optional (builtins.pathExists ../../../private/craig/default.nix) ../../../private/craig;

  hdwlinux = {
    user = {
      fullName = "Craig Wilson";
      email = "craiggwilson@gmail.com";
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL5nMCsw3AQ1HaLzvLGW51yjlKGXGR0ECeEb/WAuIGBdKs+nKo7W40d9cXN/XYH6YWZXhg/mw6RFOP5K7CB1FlVozVOqSvso2GcCUCBacjCXWrnubRUsJ5mHDdsmm3jwYGzaSNjgutVpwtj0+ijwACS5C7/m2QpatSdYFOuQhNk1KhaatoKhwWuOeh5kbpWCwUZTtTwrzphegIFDWgfErWwa0O2LKI1cVsFZkT/SgKkjILDfNJ1sYL98tKPouNrMMZj+5/tV1vxIY3UFsbAY78lZUY1yeHmTdJBjwxtG9P7+Dw4CJf9RjS35eCUA84hw95GRVfGAMj/8VasTnHsstvuNiG58lp8ufbfC8T/wGPNH7LwPmqV0TdD26s2nTikvC0qiy/QU58IeXXahI2/dmaWK+qfCayw3sL2DS/5A+HLl09lpVLLNhChnN//0mvUy0to0rCbFwqFXwmIHlveGlYdkEoRiYD4jnu/aTLfnW6YC3Ew1wVyJRH3QHXIIbWafs7R6owHWhcWEe6/CYEDAq1RTy4dknXR7DTbqhKgPX+1FnG9l9GilAwRlsb1qThHikpj2LcRvj0t0tKNO92guUAFqPyByrN9CGDimefiRqZHXkwPTl0Cr4sq3xfuW9J3wgA0u0yieLQO6EKE8adLzOfrzHEathtg+anUPYg84n2Dw== craiggwilson@gmail.com";
    };

    theme.ayu-dark.enable = true;

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
    };

    features.monitors = {
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
    };
  };
}
