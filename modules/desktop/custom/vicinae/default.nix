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
        extensions = inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        programs.vicinae = {
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
