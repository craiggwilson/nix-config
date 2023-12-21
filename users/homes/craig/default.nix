{ lib, pkgs, inputs, config, flake, ... }:
let
  privatePath = "${inputs.secrets}/craig";
  privateExists = builtins.pathExists privatePath;
in {
  imports = [
    ./gh.nix
  ] ++ lib.optional privateExists privatePath;

  hdwlinux = {
    user = {
      fullName = "Craig Wilson";
      email = "craiggwilson@gmail.com";
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL5nMCsw3AQ1HaLzvLGW51yjlKGXGR0ECeEb/WAuIGBdKs+nKo7W40d9cXN/XYH6YWZXhg/mw6RFOP5K7CB1FlVozVOqSvso2GcCUCBacjCXWrnubRUsJ5mHDdsmm3jwYGzaSNjgutVpwtj0+ijwACS5C7/m2QpatSdYFOuQhNk1KhaatoKhwWuOeh5kbpWCwUZTtTwrzphegIFDWgfErWwa0O2LKI1cVsFZkT/SgKkjILDfNJ1sYL98tKPouNrMMZj+5/tV1vxIY3UFsbAY78lZUY1yeHmTdJBjwxtG9P7+Dw4CJf9RjS35eCUA84hw95GRVfGAMj/8VasTnHsstvuNiG58lp8ufbfC8T/wGPNH7LwPmqV0TdD26s2nTikvC0qiy/QU58IeXXahI2/dmaWK+qfCayw3sL2DS/5A+HLl09lpVLLNhChnN//0mvUy0to0rCbFwqFXwmIHlveGlYdkEoRiYD4jnu/aTLfnW6YC3Ew1wVyJRH3QHXIIbWafs7R6owHWhcWEe6/CYEDAq1RTy4dknXR7DTbqhKgPX+1FnG9l9GilAwRlsb1qThHikpj2LcRvj0t0tKNO92guUAFqPyByrN9CGDimefiRqZHXkwPTl0Cr4sq3xfuW9J3wgA0u0yieLQO6EKE8adLzOfrzHEathtg+anUPYg84n2Dw== craiggwilson@gmail.com";
    };
  };

  home.sessionVariables = {
    NIX_CONFIG_FLAKE=flake;
  };

  home.shellAliases = let 
    switchCommand = "nix-config add -A . && sudo nixos-rebuild switch --flake ${flake} ${if privateExists then " --override-input secrets ${flake}/../nix-private" else ""}";
  in lib.mkMerge [
    {
      "start" = "xdg-open";
      "nix-config" = "git -C ${flake}";
      "nix-config-switch" = switchCommand;
    } 
    (lib.mkIf (lib.hdwlinux.elemsAll ["cli" "programming" "work"] config.hdwlinux.features.tags) {
      "build!" = "go run ./cmd/buildscript/build.go";
      "run!" = "go run ./cmd/mongohoused/mongohoused.go --config ./testdata/config/inline_local/frontend-agent-backend.yaml";
    })
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  home.stateVersion = "23.05";
}
