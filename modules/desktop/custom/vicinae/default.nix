{ inputs, ... }:
{
  config.substrate.modules.desktop.custom.vicinae = {
    tags = [ "desktop:custom" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors.hexWithHashtag;
        extensions = inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        services.vicinae = {
          enable = true;

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
