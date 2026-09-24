{
  config.substrate.modules.desktop.noctalia = {
    tags = [ "desktop:noctalia" ];

    # Noctalia shell: bar, notifications, launcher, clipboard, wallpaper,
    # lock screen, idle, OSD, and night light. Replaces the waybar, mako,
    # hyprpaper, hypridle/hyprlock, syshud, wlsunset, vicinae, and
    # hyprpolkitagent pieces of the desktop/custom stack.

    nixos =
      { config, ... }:
      {
        # Required by Noctalia's power-profile widget; hosts managing CPUs
        # through TLP/auto-cpufreq (e.g. unsouled) simply lose that widget.
        services.power-profiles-daemon.enable =
          !(config.services.tlp.enable or false) && !(config.services.auto-cpufreq.enable or false);
      };

    homeManager =
      {
        config,
        hasTag,
        lib,
        pkgs,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors;
        wallpaper = config.hdwlinux.theme.wallpaper;

        hasProgramming = hasTag "programming";
        hasTailscale = hasTag "networking:tailscale";
        isWork = hasTag "users:craig:work";

        mkCapsule = id: members: {
          inherit id members;

          enabled = true;
          accordion = true;
          accordion_direction = "start";
          opacity = 0.10;
          padding = 8;
          fill = "primary";
        };
        mkCapsuleEnd =
          id: members:
          (mkCapsule id members)
          // {
            accordion_direction = "end";
          };
      in
      {
        home.packages = [
          pkgs.brightnessctl
          pkgs.gpu-screen-recorder
          pkgs.python3
          pkgs.udiskie
        ];

        programs.noctalia = {
          enable = true;
          systemd.enable = true;

          customPalettes.hdwlinux = import ./_palette.nix colors;

          settings = {
            theme = {
              mode = "dark";
              source = "custom";
              custom_palette = "hdwlinux";
            };

            wallpaper = {
              enabled = true;
              fill_mode = "crop";
              default.path = "${wallpaper}";
            };

            shell = {
              font_family = "FiraCode Nerd Font";
              polkit_agent = true;
              privacy.screen_filter_regex = "obs";
              panel.transparency_mode = "glass";
            };

            location = {
              latitude = 32.7942;
              longitude = -96.7655;
            };
            nightlight.enabled = true;

            weather = {
              enabled = true;
              unit = "imperial";
            };

            idle.behavior = {
              dim = {
                enabled = true;
                timeout = 240;
                action = "command";
                command = "brightnessctl -s set 10";
                resume_command = "brightnessctl -r";
              };
              lock = {
                enabled = true;
                timeout = 300;
                action = "lock";
              };
              screen-off = {
                enabled = true;
                timeout = 360;
                action = "screen_off";
              };
              suspend = {
                enabled = true;
                timeout = 1800;
                action = "lock_and_suspend";
              };
            };

            plugins.enabled = [
              "noctalia/screen_recorder"
              "davemhammer/obsidian"
              "aristides/udiskie"
              "kenn/keybind-cheatsheet"
              "samuelskovbakke/calculator-plus"
              "weinguyen/procmon"
              "icefish/phone-connect"
            ]
            ++ lib.optionals hasProgramming [ "raycursive/github-prs" ]
            ++ lib.optionals isWork [ "levi/warp" ]
            ++ lib.optionals hasTailscale [ "rylos/tailnet" ];

            plugin_settings = {
              "aristides/udiskie".manager_placement = "attached";

              "davemhammer/obsidian" = {
                vault_path = "/home/craig/Projects/kb";
                daily_folder = "daily";
                manager_open_near_click = false;
                manager_placement = "attached";
              };

              "icefish/phone-connect".panel_open_near_click = false;

              "samuelskovbakke/calculator-plus".panel_open_near_click = false;

              "weinguyen/procmon" = {
                panel_open_near_click = false;
                panel_placement = "attached";
              };
            }
            // lib.optionalAttrs hasProgramming {
              "raycursive/github-prs".panel_open_near_click = false;
            }
            // lib.optionalAttrs hasTailscale {
              "rylos/tailnet".panel_open_near_click = false;
            }
            // lib.optionalAttrs isWork {
              "levi/warp".panel_open_near_click = false;
            };

            bar.main = {
              position = "top";
              thickness = 35;
              background_opacity = 0.6;
              margin_ends = 0;
              margin_edge = 0;
              radius = 0;
              reserve_space = true;
              widget_spacing = 10;
              color = "primary";
              contact_shadow = true;
              icon_color = "primary";
              hover_highlight = true;

              capsule_group = [
                (mkCapsule "network" (
                  [
                    "network"
                  ]
                  ++ lib.optionals hasTailscale [ "tailnet" ]
                  ++ lib.optionals isWork [ "warp" ]
                  ++ [
                    "kdeconnect"
                    "bluetooth"
                  ]
                ))
                (mkCapsule "power" [
                  "battery"
                  "procmon"
                ])
                (mkCapsuleEnd "utils" (
                  [
                    "calculator"
                    "obsidian"
                  ]
                  ++ lib.optionals hasProgramming [ "github" ]
                ))
                (mkCapsule "volume" [
                  "output"
                  "input"
                ])
              ];

              start = [
                "caffeine"
                "workspaces"
              ];

              center = [
                "visualizer"
                "privacy"
                "clock"
                "group:utils"
              ];

              end = [
                "tray"
                "udiskie"
                "group:network"
                "group:power"
                "group:volume"
                "brightness"
                "notifications"
              ];
            };

            widget = {
              battery = {
                display_mode = "graphic";
                show_label = false;
              };
              calculator.type = "samuelskovbakke/calculator-plus:widget";
              clock = {
                anchor = true;
                format = "{:%I:%M  %m/%d}";
              };
              input = {
                type = "volume";
                device = "input";
              };
              kdeconnect.type = "icefish/phone-connect:bar";
              network.show_label = false;
              obsidian.type = "davemhammer/obsidian:status";

              output = {
                type = "volume";
                device = "output";
              };
              privacy = {
                active_color = "error";
                hide_inactive = true;
              };
              procmon.type = "weinguyen/procmon:widget";
              tray = {
                drawer = true;
                match_adjacent_spacing = true;
                pinned = [ "1Password" ];
              };
              udiskie.type = "aristides/udiskie:status";
              visualizer.type = "audio_visualizer";
              workspaces.hide_when_empty = false;
            }
            // lib.optionalAttrs hasProgramming {
              github.type = "raycursive/github-prs:bar";
            }
            // lib.optionalAttrs isWork {
              warp.type = "levi/warp:warp";
            }
            // lib.optionalAttrs hasTailscale {
              tailnet.type = "rylos/tailnet:bar";
            };
          };
        };
      };
  };
}
