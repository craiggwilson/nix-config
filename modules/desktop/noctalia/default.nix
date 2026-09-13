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
        host,
        lib,
        pkgs,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors;
        wallpaper = config.hdwlinux.theme.wallpaper;

        # The opencode-companion plugin only exists where ai:clients is tagged;
        # its default model follows the primary ("fast") alias.
        hasAiClients = hasTag "ai:clients";
        fastModel = lib.head (
          map (m: "${m.provider}/${m.model}") config.hdwlinux.ai.clients.models.aliases.fast.models
        );
      in
      {
        home.packages = [
          pkgs.brightnessctl
          pkgs.gpu-screen-recorder
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

            plugin_settings = {
              "davemhammer/obsidian" = {
                vault_path = "/home/craig/Projects/kb";
                daily_folder = "daily";
              };
              "mindnbytes/nix-status" = {
                flake_dir = config.hdwlinux.flake;
                nixos_configuration = host;
              };
            }
            // lib.optionalAttrs hasAiClients {
              "weinguyen/opencode-companion" = {
                default_model = fastModel;
                # Use the systemd-managed opencode-web service
                # (programs.opencode.web) instead of the plugin's own server.
                server_mode = "external";
                server_url = "http://127.0.0.1:4096";
                "panel-fill_position" = "top_right";
                auto_start = false;
              };
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
            weather.unit = "imperial";

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
              "mindnbytes/nix-status"
              "davemhammer/obsidian"
              "aristides/udiskie"
            ]
            ++ lib.optionals hasAiClients [ "weinguyen/opencode-companion" ]
            ++ lib.optionals (hasTag "users:craig:work") [ "levi/warp" ]
            ++ lib.optionals (hasTag "users:craig:personal") [ "rylos/tailnet" ];

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

              start = [
                "caffeine"
                "workspaces"
              ];

              center = [
                "obsidian"
                "clock"
              ]
              ++ lib.optionals hasAiClients [ "opencode" ]
              ++ [
                "privacy"
                "visualizer"
              ];

              end = [
                "tray"
                "udiskie"
                "bluetooth"
              ]
              ++ lib.optionals (hasTag "users:craig:work") [ "warp" ]
              ++ lib.optionals (hasTag "users:craig:personal") [ "tailnet" ]
              ++ [
                "network"
                "battery"
                "brightness"
                "volume"
                "mic"
                "notifications"
                "session"
              ];
            };

            widget = {
              clock.format = "{:%I:%M  %m/%d}";

              # Show every workspace, not just occupied ones (old ext/workspaces behavior).
              workspaces.hide_when_empty = false;

              network.show_label = false;

              battery = {
                display_mode = "graphic";
                show_label = false;
              };

              cpu = {
                type = "sysmon";
                stat = "cpu_usage";
                visualization = "gauge";
                show_value = true;
              };

              mem = {
                type = "sysmon";
                stat = "ram_pct";
                visualization = "gauge";
                show_value = true;
              };

              temp = {
                type = "sysmon";
                stat = "cpu_temp";
                visualization = "gauge";
                show_value = true;
              };

              net_tx = {
                type = "sysmon";
                stat = "net_tx";
                visualization = "none";
                show_value = true;
              };

              net_rx = {
                type = "sysmon";
                stat = "net_rx";
                visualization = "none";
                show_value = true;
              };

              visualizer.type = "audio_visualizer";

              mic = {
                type = "volume";
                device = "input";
              };

              # Hide warp-taskbar's StatusNotifierItem (Cloudflare WARP); the
              # levi/warp bar widget covers its state. udiskie's tray icon is
              # disabled at the source via services.udiskie.tray.
              tray = {
                drawer = true;
                match_adjacent_spacing = true;
              };

              privacy = {
                active_color = "error";
                hide_inactive = true;
              };

              # Plugin bar widgets (community source).
              nix-status.type = "mindnbytes/nix-status:status";
              obsidian.type = "davemhammer/obsidian:status";
              udiskie.type = "aristides/udiskie:status";
            }
            // lib.optionalAttrs hasAiClients {
              opencode.type = "weinguyen/opencode-companion:widget";
            }
            // lib.optionalAttrs (hasTag "users:craig:work") {
              warp.type = "levi/warp:warp";
            }
            // lib.optionalAttrs (hasTag "users:craig:personal") {
              tailnet.type = "rylos/tailnet:bar";
            };
          };
        };
      };
  };
}
