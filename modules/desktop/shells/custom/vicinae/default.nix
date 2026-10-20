{ inputs, ... }:
{
  config.substrate.modules.desktop.shells.custom.vicinae = {
    tags = [ "desktop:shells:custom" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        system = pkgs.stdenv.hostPlatform.system;
        colors = config.hdwlinux.theme.colors.hexWithHashtag;
        extensions = inputs.vicinae-extensions.packages.${system};

        # The upstream vicinae flake builds vicinae with gcc15Stdenv but its
        # bundled numen with the default stdenv (gcc16 on current nixpkgs).
        # Linking numen's gcc16 libstdc++ into the gcc15 binary fails on the
        # GLIBCXX_3.4.36 symbol, so rebuild numen with gcc15Stdenv to match.
        # Drop this once upstream fixes nix/vicinae.nix and flake.nix.
        numen = inputs.vicinae.inputs.numen.packages.${system}.numen.override {
          withRepl = false;
          stdenv = pkgs.gcc15Stdenv;
        };
        vicinae = inputs.vicinae.packages.${system}.default.override { inherit numen; };
      in
      {
        # Overrides the vicinae module's default (which has no condition).
        systemd.user.services.vicinae.Unit.ConditionEnvironment = lib.mkForce "HDWLINUX_SHELL=custom";

        programs.vicinae = {
          enable = true;
          package = vicinae;

          systemd = {
            enable = true;
            autoStart = true;
            environment = {
              USE_LAYER_SHELL = 1;
            };
          };

          extensions = [
            extensions.nerdfont-search
            extensions.niri
            extensions.nix
            extensions.wifi-commander
          ];

          themes = {
            hdwlinux = {
              meta = {
                version = 1;
                name = "hdwlinux";
                description = "HDW Linux theme using base16 colors";
                variant = "dark";
              };
              colors = {
                core = {
                  background = {
                    name = colors.base00;
                    opacity = 0.64;
                  };
                  foreground = colors.base05;
                  secondary_background = {
                    name = colors.base01;
                    opacity = 0.72;
                  };
                  border = {
                    name = colors.base02;
                    opacity = 0.42;
                  };
                  accent = colors.base0D;
                };
                accents = {
                  blue = colors.base0D;
                  green = colors.base0B;
                  magenta = colors.base0E;
                  orange = colors.base09;
                  purple = colors.base0E;
                  red = colors.base08;
                  yellow = colors.base0A;
                  cyan = colors.base0C;
                };
                list.item.selection = {
                  background = colors.base02;
                  secondary_background = colors.base03;
                };
              };
            };
          };

          settings = {
            theme = {
              dark = {
                name = "hdwlinux";
              };
              light = {
                name = "hdwlinux";
              };
            };
            launcher_window = {
              opacity = 0.82;
              blur = {
                enabled = true;
              };
            };
          };
        };
      };
  };
}
