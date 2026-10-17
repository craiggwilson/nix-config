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
        wrap,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors;
        wallpaper = config.hdwlinux.theme.wallpaper;

        hasAI = hasTag "ai:clients";
        hasProgramming = hasTag "programming";
        hasTailscale = hasTag "networking:tailscale";
        isWork = hasTag "users:craig:work";

        # tordex/processes shells out to a bare `python`, and alok-debnath/shelf
        # both probes `python3` for a GTK 4 import and then runs its drop
        # window with it. Neither resolves an interpreter from config, so a
        # GTK-capable one has to own both names on the PATH noctalia hands its
        # plugins. Only noctalia gets it; see the wrapper below.
        gtkPython =
          let
            interpreter = pkgs.python3.withPackages (
              ps: with ps; [
                pillow
                psutil
                pygobject3
              ]
            );
          in
          pkgs.stdenv.mkDerivation {
            name = "noctalia-gtk-python";

            dontUnpack = true;
            dontConfigure = true;

            # gobject-introspection's setup hook walks buildInputs and collects their
            # lib/girepository-1.0 into GI_TYPELIB_PATH; wrapGAppsHook4 bakes
            # that (plus pixbuf loaders, gio modules and icon themes) into every
            # executable in $out/bin during fixupPhase, so the GTK dependency
            # list never has to be written out by hand.
            # CAVEAT: dontUnpack (needed, there is no src) also skips the
            # dependency-addition hooks, so GI_TYPELIB_PATH comes out empty and
            # only the loaders and themes land. gi.repository.Gtk therefore does
            # not import yet, which means alok-debnath/shelf and tordex/processes
            # are configured but non-functional until that path is set by hand.
            nativeBuildInputs = [
              pkgs.gobject-introspection
              pkgs.makeWrapper
              pkgs.wrapGAppsHook4
            ];
            buildInputs = [
              pkgs.adwaita-icon-theme
              pkgs.dejavu_fonts
              pkgs.gtk3
              pkgs.gtk4
              pkgs.gtk4-layer-shell
              pkgs.hicolor-icon-theme
            ];

            installPhase = ''
              runHook preInstall

              for name in python python3; do
                makeWrapper ${interpreter}/bin/python3 "$out/bin/$name"
              done

              runHook postInstall
            '';
          };

        # Everything the shell and its plugins shell out to, on noctalia's PATH and
        # nowhere else. gtk4 / gtk4-layer-shell are not here because nothing
        # execs them: they are libraries, dlopened by gtkPython, which carries
        # them through its own GI_TYPELIB_PATH.
        noctalia = wrap.package {
          package = pkgs.noctalia;
          runtimeInputs = [
            pkgs.brightnessctl
            gtkPython
            pkgs.gpu-screen-recorder
            pkgs.udiskie
          ];
        };

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
        programs.noctalia = {
          enable = true;
          systemd.enable = true;
          package = noctalia;

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

              # Open the launcher from wherever it was summoned rather than
              # sliding it in from the edge.
              panel.launcher_placement = "attached";
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
              "alok-debnath/shelf"
              "tordex/processes"
              "turja-roy/todoist"
            ]
            ++ lib.optionals hasAI [
              "hy4ri/herdr"
              "zumik3-del/opencode-go-usage"
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

              "hy4ri/herdr".panel_open_near_click = false;

              "samuelskovbakke/calculator-plus".panel_open_near_click = false;

              "tordex/processes".panel_open_near_click = false;

              # NOTE: no api_key here on purpose. This plugin only reads its key
              # from this setting, and anything written from Nix is readable in
              # /nix/store. Set it once in Noctalia's Settings > Plugins, where
              # it stays in the user's own state file.

              "zumik3-del/opencode-go-usage".panel_open_near_click = false;

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
                  "processes"
                  "procmon"
                ])
                (mkCapsuleEnd "utils" (
                  [
                    "shelf"
                    "calculator"
                    "obsidian"
                  ]
                  ++ lib.optionals hasProgramming [ "github" ]
                ))
                (mkCapsule "volume" [
                  "output"
                  "input"
                ])
              ]
              ++ lib.optionals hasAI [
                # Herdr turns red when an agent is blocked, so this wants to be
                # glanceable rather than tucked behind a panel.
                (mkCapsule "ai" [
                  "herdr"
                  "opencode"
                ])
              ];

              start = [
                "caffeine"
                "workspaces"
                "visualizer"
                "media"
              ];

              center = lib.optionals hasAI [ "group:ai" ] ++ [
                "privacy"
                "clock"
                "todoist"
                "group:utils"
              ];

              # todoist, shelf and processes have no chosen home yet — they are
              # parked here only so they are configured and usable. Move them
              # once you have settled on a layout.
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
              media = {
                max_length = 500;
                scale = 0.75;
              };
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
              processes.type = "tordex/processes:widget";
              shelf.type = "alok-debnath/shelf:shelf";
              todoist.type = "turja-roy/todoist:widget";
              tray = {
                drawer = true;
                match_adjacent_spacing = true;
                pinned = [ "1Password" ];

                # Blueman registers a StatusNotifierItem ("blueman") for the
                # bluetooth applet. The built-in bluetooth bar widget in
                # group:network already covers it, so drop the duplicate tray
                # icon. Tokens match exactly, so this is the SNI Id property.
                hidden = [ "blueman" ];
              };
              udiskie.type = "aristides/udiskie:status";
              visualizer.type = "audio_visualizer";
              workspaces.hide_when_empty = false;
            }
            // lib.optionalAttrs hasAI {
              herdr.type = "hy4ri/herdr:bar";
              opencode.type = "zumik3-del/opencode-go-usage:bar";
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
