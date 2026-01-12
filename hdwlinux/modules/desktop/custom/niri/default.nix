{
  config.substrate.modules.desktop.custom.niri = {
    tags = [
      "gui"
      "desktop:custom:niri"
    ];

    nixos =
      { lib, pkgs, ... }:
      {
        programs = {
          niri.enable = true;
          uwsm = {
            enable = true;
            waylandCompositors = {
              niri = {
                prettyName = "Niri";
                comment = "Niri managed by UWSM";
                binPath = "/run/current-system/sw/bin/niri-session";
              };
            };
          };
        };

        services.xserver.desktopManager.runXdgAutostartIfNone = true;

        systemd.packages = [ pkgs.niri ];

        environment.sessionVariables = {
          GSK_RENDERER = "gl";
        };

        xdg.portal = {
          enable = true;
          configPackages = [ pkgs.niri ];
          config.niri = {
            # Use mkForce to override nixpkgs default
            default = lib.mkForce [
              "gtk"
              "wlr"
            ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
          extraPortals = [
            pkgs.xdg-desktop-portal-gnome
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-wlr
          ];
          xdgOpenUsePortal = true;
        };
      };

    homeManager =
      {
        inputs,
        config,
        pkgs,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors.withHashtag;
      in
      {
        home.packages = [
          (pkgs.xwayland-satellite.override { withSystemd = false; })
          inputs.niri-scratchpad.packages.${pkgs.stdenv.hostPlatform.system}.niri-scratchpad
        ];

        home.sessionVariables.NIRI_DISABLE_SYSTEM_MANAGER_NOTIFY = "1";

        systemd.user.startServices = true;

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
          config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/modules/desktop/custom/niri/config/functional.kdl";
      };
  };
}
