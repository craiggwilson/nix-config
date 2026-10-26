{ lib, ... }:
let
  name = "craig";
  fullName = "Craig Wilson";
  email = "craiggwilson@gmail.com";
  publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL5nMCsw3AQ1HaLzvLGW51yjlKGXGR0ECeEb/WAuIGBdKs+nKo7W40d9cXN/XYH6YWZXhg/mw6RFOP5K7CB1FlVozVOqSvso2GcCUCBacjCXWrnubRUsJ5mHDdsmm3jwYGzaSNjgutVpwtj0+ijwACS5C7/m2QpatSdYFOuQhNk1KhaatoKhwWuOeh5kbpWCwUZTtTwrzphegIFDWgfErWwa0O2LKI1cVsFZkT/SgKkjILDfNJ1sYL98tKPouNrMMZj+5/tV1vxIY3UFsbAY78lZUY1yeHmTdJBjwxtG9P7+Dw4CJf9RjS35eCUA84hw95GRVfGAMj/8VasTnHsstvuNiG58lp8ufbfC8T/wGPNH7LwPmqV0TdD26s2nTikvC0qiy/QU58IeXXahI2/dmaWK+qfCayw3sL2DS/5A+HLl09lpVLLNhChnN//0mvUy0to0rCbFwqFXwmIHlveGlYdkEoRiYD4jnu/aTLfnW6YC3Ew1wVyJRH3QHXIIbWafs7R6owHWhcWEe6/CYEDAq1RTy4dknXR7DTbqhKgPX+1FnG9l9GilAwRlsb1qThHikpj2LcRvj0t0tKNO92guUAFqPyByrN9CGDimefiRqZHXkwPTl0Cr4sq3xfuW9J3wgA0u0yieLQO6EKE8adLzOfrzHEathtg+anUPYg84n2Dw== craiggwilson@gmail.com";
  commonTags = [
    "core:security:passwordmanager"
    "core:security:secrets"
    "core:security:yubikey"
    "desktop:theming:catppuccin"
  ];
in
{
  substrate.users = {
    "${name}@personal" = {
      tags = [
        "user:${name}"
        "capability:audio"
        "capability:displaylink"
        "capability:filesystem:cifs"
        "capability:gaming-controller"
        "capability:midi"
        "capability:performance"
        "capability:virtualization:podman"
        "core:base"
        "core:networking:tailscale"
        "core:ssh"
        "core:tools:cloud-sync"
        "core:tools:system"
        "desktop"
        "desktop:compositors:hyprland"
        "desktop:compositors:niri"
        "desktop:flatpaks"
        "desktop:shells:dux"
        "desktop:shells:noctalia"
        "profile:ai"
        "profile:gaming"
        "profile:personal"
        "profile:programming"
        "role:audio-production"
        "role:video-production"
        "service:ai:image-generation"
        "service:ai:llm"
      ]
      ++ commonTags;
    };
    "${name}@work" = {
      tags = [
        "user:${name}"
        "capability:filesystem:cifs"
        "capability:filesystem:envfs"
        "core:base"
        "core:security:passwordmanager"
        "core:ssh"
        "core:tools:system"
        "desktop"
        "desktop:compositors:hyprland"
        "desktop:compositors:niri"
        "desktop:shells:dux"
        "desktop:shells:noctalia"
        "profile:ai"
        "profile:programming"
        "profile:work"
      ]
      ++ commonTags;
    };
  };

  substrate.modules.users.${name} = {
    tags = [ "user:${name}" ];

    nixos =
      {
        hasTag,
        ...
      }:
      {
        nix.settings = {
          trusted-users = [ name ];
          allowed-users = [ name ];
        };

        nix.extraOptions = lib.mkIf (hasTag "profile:programming") ''
          !include /home/${name}/.config/hdwlinux/secrets/nixGithubAccessTokens
        '';

        users.users.${name} = {
          uid = 1000;
          extraGroups = [
            "inputs"
            "wheel"
          ]
          ++ lib.optionals (hasTag "capability:audio") [ "audio" ]
          ++ lib.optionals (hasTag "capability:printing") [ "lp" ]
          ++ lib.optionals (hasTag "capability:scanning") [ "scanner" ]
          ++ lib.optionals (hasTag "core:networking") [ "networkmanager" ]
          ++ lib.optionals (hasTag "capability:virtualization:docker") [ "docker" ]
          ++ lib.optionals (hasTag "core:security:passwordmanager") [ "onepassword-cli" ]
          ++ lib.optionals (hasTag "desktop" && hasTag "core:security:passwordmanager") [
            "onepassword"
          ];

          openssh.authorizedKeys.keys = [ publicKey ];
        };

        users.groups.users.gid = 100;

        programs._1password-gui.polkitPolicyOwners = lib.mkIf (
          hasTag "desktop" && hasTag "core:security:passwordmanager"
        ) [ name ];

        hdwlinux.filesystems.cifs.mounts =
          (lib.optionals (hasTag "location:raeford" && hasTag "profile:personal") [
            {
              group = "users";
              local = "/home/${name}/mnt/synology/games";
              remote = "//synology/games";
              owner = "${name}";
              username = "craiggwilson";
            }
            {
              group = "users";
              local = "/home/${name}/mnt/synology/music";
              remote = "//synology/music";
              owner = "${name}";
              username = "craiggwilson";
            }
            {
              group = "users";
              local = "/home/${name}/mnt/synology/photos";
              remote = "//synology/photo";
              owner = "${name}";
              username = "craiggwilson";
            }
          ])
          ++ (lib.optionals
            (hasTag "location:raeford" && (hasTag "profile:personal" || hasTag "profile:work"))
            [
              {
                group = "users";
                local = "/home/${name}/mnt/synology/home";
                remote = "//synology/home";
                owner = "${name}";
                username = "craiggwilson";
              }
            ]
          );

      };

    homeManager =
      { config, hasTag, ... }:
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
            GITHUB_API_TOKEN = lib.mkIf (hasTag "profile:programming") {
              description = "GitHub API token for API access and nix flake fetches.";
              ref = {
                vault = "Craig";
                item = "Github";
                field = "api_token";
              };
            };
            NIX_GITHUB_ACCESS_TOKENS = lib.mkIf (hasTag "profile:programming") {
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
