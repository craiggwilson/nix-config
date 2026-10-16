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
      tags = [
        "users:${name}:personal"
      ];

      provides = [
        "users:${name}"
        "profiles:personal"
      ];

      requires = [
        # Feature capabilities this identity asks for. These replace the
        # users:craig:personal meta-tag expansion from the tags catalogue:
        # capability requires filter, they never pull, so every leaf the
        # user wants is named here.
        "core:security"
        "ai:clients"
        "ai:image"
        "ai:llm"
        "audio:production"
        "cloud:sync"
        "desktop:noctalia:niri"
        "gui"
        "filesystem:nfs"
        "apps:flatpak"
        "gaming"
        "networking:tailscale"
        "virtualization:podman"
        "programming"
        "security:passwordmanager"
        "security:secrets"
        "theming:catppuccin"
        "video:production"
        "hardware:yubikey"
      ];
    };
    "${name}@work" = {
      tags = [
        "users:${name}:work"
      ];

      provides = [
        "users:${name}"
        "profiles:work"
      ];

      requires = [
        "core:security"
        "ai:clients"
        "cloud:sync"
        "desktop:noctalia:niri"
        "gui"
        "filesystem:envfs"
        "virtualization:docker"
        "programming"
        "security:passwordmanager"
        "security:secrets"
        "theming:catppuccin"
        "video:production"
        "hardware:yubikey"
      ];
    };
  };

  substrate.modules.users.${name} = {
    tags = [ "users:${name}" ];
    provides = [ "users:${name}" ];

    nixos =
      { hasCapability, ... }:
      {
        nix.settings = {
          trusted-users = [ name ];
          allowed-users = [ name ];
        };

        nix.extraOptions = lib.mkIf (hasCapability "programming") ''
          !include /home/${name}/.config/hdwlinux/secrets/nixGithubAccessTokens
        '';

        users.users.${name} = {
          extraGroups = [
            "inputs"
            "wheel"
          ]
          ++ lib.optionals (hasCapability "hardware:audio") [ "audio" ]
          ++ lib.optionals (hasCapability "hardware:printing") [ "lp" ]
          ++ lib.optionals (hasCapability "hardware:scanning") [ "scanner" ]
          ++ lib.optionals (hasCapability "hardware:networking") [ "networkmanager" ]
          ++ lib.optionals (hasCapability "virtualization:docker") [ "docker" ]
          ++ lib.optionals (hasCapability "security:passwordmanager") [ "onepassword-cli" ]
          ++ lib.optionals (hasCapability "gui" && hasCapability "security:passwordmanager") [
            "onepassword"
          ];

          openssh.authorizedKeys.keys = [ publicKey ];
        };

        programs._1password-gui.polkitPolicyOwners = lib.mkIf (
          hasCapability "gui" && hasCapability "security:passwordmanager"
        ) [ name ];
      };

    homeManager =
      { config, hasCapability, ... }:
      {
        hdwlinux.user = {
          inherit
            name
            fullName
            email
            publicKey
            ;
        };

        secretspec = {
          entries = {
            personalSshKey = {
              description = "Personal SSH private key used for signing and authenticated git access.";
              ref = {
                vault = "Craig";
                item = "SSH Key - Craig";
                field = "private key";
              };
              file.path = "${config.home.homeDirectory}/.ssh/id_rsa";
            };
            GITHUB_API_TOKEN = lib.mkIf (hasCapability "programming") {
              description = "GitHub API token for API access and nix flake fetches.";
              ref = {
                vault = "Craig";
                item = "Github";
                field = "api_token";
              };
            };
            NIX_GITHUB_ACCESS_TOKENS = lib.mkIf (hasCapability "programming") {
              description = "Nix GitHub access-tokens file composed from GITHUB_API_TOKEN.";
              composed = "access-tokens = github.com=\${GITHUB_API_TOKEN}";
              file.path = "${config.xdg.configHome}/hdwlinux/secrets/nixGithubAccessTokens";
            };
          };
        };

        home.shellAliases = {
          "nix-update" = ''
            set -e
            # nix flake update doesn't write flake.lock when the source is a jj
            # repo because jj's git backend causes nix to resolve the flake from
            # an immutable store path. Work around by temporarily hiding .git so
            # nix uses the path: fetcher and writes directly to the filesystem.
            _nix_config_dir=$(git -C "''${1:-.}" rev-parse --show-toplevel 2>/dev/null || echo "''${1:-.}")
            mv "$_nix_config_dir/.git" "$_nix_config_dir/.git.bak"
            nix flake update --flake "$_nix_config_dir" --allow-dirty-locks || { mv "$_nix_config_dir/.git.bak" "$_nix_config_dir/.git"; return 1; }
            mv "$_nix_config_dir/.git.bak" "$_nix_config_dir/.git"
          '';
          "start" = "xdg-open";
          "use" = "hdwlinux develop";
        };

        home.stateVersion = "23.05";
      };
  };
}
