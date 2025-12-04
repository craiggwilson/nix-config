{
  config,
  flake,
  lib,
  pkgs,
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

    home.sessionVariables.NIRI_DISABLE_SYSTEM_MANAGER_NOTIFY = "1";

    xdg.configFile."niri/config.kdl".text = ''
      include "colors.kdl"
      include "functional.kdl"
    '';

    xdg.configFile."niri/colors.kdl".text = ''
      layout {
          background-color "${colors.base00}"

          focus-ring {
              active-gradient from="${colors.base0E}" to="${colors.base0D}" angle=60
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
              active-color "${colors.base08}80"
          }
          shadow {
              "on"
              color "${colors.base08}80"
          }
      }
      window-rule {
          match is-urgent=true
          shadow {
              "on"
              color "${colors.base06}"
          }
      }
    '';
    xdg.configFile."niri/functional.kdl".source =
      config.lib.file.mkOutOfStoreSymlink "${flake}/modules/home/desktopManagers/wayland/niri/config/functional.kdl";
  };
}
