{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.hdwlinux.desktopManagers.wayland.niri;
  colors = config.hdwlinux.theme.colors.withHashtag;
in
{
  options.hdwlinux.desktopManagers.wayland.niri = {
    enable = config.lib.hdwlinux.mkEnableOption "niri" "desktop:niri";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.startServices = true;

    hdwlinux.desktopManagers.wayland.screen.monitors = {
      on = ''if [ "$XDG_CURRENT_DESKTOP" = "niri" ]; then ${pkgs.niri}/bin/niri msg action power-on-monitors; fi'';
      off = ''if [ "$XDG_CURRENT_DESKTOP" = "niri" ]; then ${pkgs.niri}/bin/niri msg action power-off-monitors; fi'';
    };

    home.packages = [
      inputs.niri-scratchpad.packages.${pkgs.system}.niri-scratchpad
    ];
    home.sessionVariables.NIRI_DISABLE_SYSTEM_MANAGER_NOTIFY = "1";

    xdg.configFile."niri/config.kdl".text = ''
      include "colors.kdl"
      include "functional.kdl"
    '';

    xdg.configFile."niri/colors.kdl".text = ''
      layout {
          background-color "${colors.base00}"

          focus-ring {
              active-color "${colors.base0E}"
              inactive-color "${colors.base03}"
              urgent-color "${colors.base06}"
          }

          insert-hint {
              color "${colors.base09}80"
          }

          tab-indicator {
              active-color "${colors.base0B}"
              inactive-color "${colors.base03}"
              urgent-color "${colors.base06}"
          }
      }

      overview {
          backdrop-color "${colors.base00}"
      }

      window-rule {
          match is-window-cast-target=true
          focus-ring {
              active-color "${colors.base0A}80"
          }
          shadow {
              on
              
              color "${colors.base0A}80"
          }
      }

      window-rule {
          match is-floating=true

          shadow {
              on

              softness 40
              draw-behind-window true
              spread 25
              color "#7d0d2d70"
          }

          opacity 0.95

          focus-ring {
              active-color "${colors.base08}"
          }
      }
    '';
    xdg.configFile."niri/functional.kdl".source =
      config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/modules/home/desktopManagers/wayland/niri/config/functional.kdl";
  };
}
