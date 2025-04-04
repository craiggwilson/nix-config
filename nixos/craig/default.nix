{
  inputs,
  config,
  lib,
  ...
}:
let
  username = "craig";
  privatePath = "${inputs.secrets}/nixos/${username}";
  privateExists = builtins.pathExists privatePath;
in
{
  imports = lib.optionals privateExists [ privatePath ];

  hdwlinux = {
    nix.flake = "/home/craig/Projects/github.com/craiggwilson/nix-config";

    filesystems.nfs.mounts = lib.optionals (lib.hdwlinux.matchTag "gaming" config.hdwlinux.tags) [
      {
        local = "/mnt/games";
        remote = "synology.raeford.wilsonfamilyhq.com:/volume2/games";
        auto = true;
      }
    ];
  };

  nix.settings = {
    trusted-users = [ username ];
    allowed-users = [ username ];
  };

  users.users.${username} = {
    isNormalUser = true;

    name = username;
    home = "/home/${username}";
    group = "users";
    initialPassword = "password";

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL5nMCsw3AQ1HaLzvLGW51yjlKGXGR0ECeEb/WAuIGBdKs+nKo7W40d9cXN/XYH6YWZXhg/mw6RFOP5K7CB1FlVozVOqSvso2GcCUCBacjCXWrnubRUsJ5mHDdsmm3jwYGzaSNjgutVpwtj0+ijwACS5C7/m2QpatSdYFOuQhNk1KhaatoKhwWuOeh5kbpWCwUZTtTwrzphegIFDWgfErWwa0O2LKI1cVsFZkT/SgKkjILDfNJ1sYL98tKPouNrMMZj+5/tV1vxIY3UFsbAY78lZUY1yeHmTdJBjwxtG9P7+Dw4CJf9RjS35eCUA84hw95GRVfGAMj/8VasTnHsstvuNiG58lp8ufbfC8T/wGPNH7LwPmqV0TdD26s2nTikvC0qiy/QU58IeXXahI2/dmaWK+qfCayw3sL2DS/5A+HLl09lpVLLNhChnN//0mvUy0to0rCbFwqFXwmIHlveGlYdkEoRiYD4jnu/aTLfnW6YC3Ew1wVyJRH3QHXIIbWafs7R6owHWhcWEe6/CYEDAq1RTy4dknXR7DTbqhKgPX+1FnG9l9GilAwRlsb1qThHikpj2LcRvj0t0tKNO92guUAFqPyByrN9CGDimefiRqZHXkwPTl0Cr4sq3xfuW9J3wgA0u0yieLQO6EKE8adLzOfrzHEathtg+anUPYg84n2Dw== craiggwilson@gmail.com"
    ];

    extraGroups =
      [
        "wheel"
        "inputs"
      ]
      ++ (lib.optionals config.hdwlinux.hardware.audio.enable [ "audio" ])
      ++ (lib.optionals config.hdwlinux.hardware.printers.enable [ "lp" ])
      ++ (lib.optionals config.hdwlinux.hardware.sane.enable [ "scanner" ])
      ++ (lib.optionals config.hdwlinux.networking.enable [ "networkmanager" ])
      ++ (lib.optionals config.hdwlinux.programs._1password-cli.enable [ "onepassword-cli" ])
      ++ (lib.optionals config.hdwlinux.programs._1password-gui.enable [ "onepassword" ])
      ++ (lib.optionals config.hdwlinux.virtualization.docker.enable [ "docker" ]);
  };

  programs._1password-gui.polkitPolicyOwners =
    lib.mkIf config.hdwlinux.programs._1password-gui.enable
      [ username ];
}
