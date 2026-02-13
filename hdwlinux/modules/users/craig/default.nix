{ lib, ... }:
let
  name = "craig";
  fullName = "Craig Wilson";
  email = "craiggwilson@gmail.com";
  publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL5nMCsw3AQ1HaLzvLGW51yjlKGXGR0ECeEb/WAuIGBdKs+nKo7W40d9cXN/XYH6YWZXhg/mw6RFOP5K7CB1FlVozVOqSvso2GcCUCBacjCXWrnubRUsJ5mHDdsmm3jwYGzaSNjgutVpwtj0+ijwACS5C7/m2QpatSdYFOuQhNk1KhaatoKhwWuOeh5kbpWCwUZTtTwrzphegIFDWgfErWwa0O2LKI1cVsFZkT/SgKkjILDfNJ1sYL98tKPouNrMMZj+5/tV1vxIY3UFsbAY78lZUY1yeHmTdJBjwxtG9P7+Dw4CJf9RjS35eCUA84hw95GRVfGAMj/8VasTnHsstvuNiG58lp8ufbfC8T/wGPNH7LwPmqV0TdD26s2nTikvC0qiy/QU58IeXXahI2/dmaWK+qfCayw3sL2DS/5A+HLl09lpVLLNhChnN//0mvUy0to0rCbFwqFXwmIHlveGlYdkEoRiYD4jnu/aTLfnW6YC3Ew1wVyJRH3QHXIIbWafs7R6owHWhcWEe6/CYEDAq1RTy4dknXR7DTbqhKgPX+1FnG9l9GilAwRlsb1qThHikpj2LcRvj0t0tKNO92guUAFqPyByrN9CGDimefiRqZHXkwPTl0Cr4sq3xfuW9J3wgA0u0yieLQO6EKE8adLzOfrzHEathtg+anUPYg84n2Dw== craiggwilson@gmail.com";
in
{
  substrate.users = {
    "${name}@personal" = {
      inherit name;
      tags = [
        "users:${name}:personal"
      ];
    };
    "${name}@work" = {
      inherit name;
      tags = [
        "users:${name}:work"
      ];
    };
  };

  substrate.modules.users.${name} = {
    tags = [ "users:${name}" ];

    nixos =
      { hasTag, ... }:
      {
        hdwlinux.security.secrets.users = [ name ];

        nix.settings = {
          trusted-users = [ name ];
          allowed-users = [ name ];
        };

        users.users.${name} = {
          extraGroups = [
            "inputs"
            "wheel"
          ]
          ++ lib.optionals (hasTag "audio") [ "audio" ]
          ++ lib.optionals (hasTag "printing") [ "lp" ]
          ++ lib.optionals (hasTag "scanning") [ "scanner" ]
          ++ lib.optionals (hasTag "networking") [ "networkmanager" ]
          ++ lib.optionals (hasTag "virtualization:docker") [ "docker" ]
          ++ lib.optionals (hasTag "security:passwordmanager") [ "onepassword-cli" ]
          ++ lib.optionals (hasTag "gui" && hasTag "security:passwordmanager") [ "onepassword" ];

          openssh.authorizedKeys.keys = [ publicKey ];
        };

        programs._1password-gui.polkitPolicyOwners = lib.mkIf (
          hasTag "gui" && hasTag "security:passwordmanager"
        ) [ name ];
      };

    homeManager =
      { config, hasTag, ... }:
      {
        hdwlinux = {
          user = {
            inherit
              name
              fullName
              email
              publicKey
              ;
          };

          security.secrets.entries.personalSshKey = {
            path = "${config.home.homeDirectory}/.ssh/id_rsa";
            reference = "op://Craig/SSH Key - Craig/private key";
            mode = "0600";
          };

          security.secrets.entries.githubApiToken = lib.mkIf (hasTag "programming") {
            reference = "op://Craig/Github/api_token";
            mode = "0600";
          };
        };

        home.shellAliases = {
          "start" = "xdg-open";
          "use" = "hdwlinux develop";
        };

        home.stateVersion = "23.05";
      };
  };
}
