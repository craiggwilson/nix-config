{ inputs, ... }:
{
  config.substrate.modules.programs.herdr = {
    tags = [
      "ai:clients"
      "programming"
    ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors.hexWithHashtag;

        herdrPkg = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;

        pluginKeybindingType = lib.types.submodule {
          options = {
            key = lib.mkOption {
              description = "Key chord that triggers the plugin action.";
              type = lib.types.str;
            };
            type = lib.mkOption {
              description = "Type of the keybinding, forwarded to the generated herdr config.toml.";
              type = lib.types.str;
              default = "plugin_action";
            };
            command = lib.mkOption {
              description = "Qualified plugin action, e.g. `<plugin-id>.<action>`.";
              type = lib.types.str;
            };
            description = lib.mkOption {
              description = "Human-readable description shown in the herdr UI.";
              type = lib.types.str;
            };
          };
        };

        pluginType = lib.types.submodule {
          options = {
            id = lib.mkOption {
              description = ''
                The herdr plugin id, as shown by `herdr plugin list`. This is the
                prefix used for qualified action commands, e.g. `<id>.open-file-viewer`.
              '';
              type = lib.types.str;
            };
            source = lib.mkOption {
              description = ''
                GitHub source shorthand accepted by `herdr plugin install`,
                e.g. `owner/repo` or `owner/repo/subdir`.
              '';
              type = lib.types.str;
            };
            ref = lib.mkOption {
              description = "Optional git ref to pin the installed plugin to.";
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            keybindings = lib.mkOption {
              description = ''
                Plugin action keybindings bundled with the plugin, merged into
                the `keys.command` list of the generated config.toml.
              '';
              type = lib.types.listOf pluginKeybindingType;
              default = [ ];
            };
            buildInputs = lib.mkOption {
              description = ''
                Toolchain packages (e.g. `pkgs.cargo`, `pkgs.go`) to prepend to
                `PATH` only while installing this plugin, for plugins whose
                `[[build]]` step compiles from source at install time. Plugins
                that ship prebuilt binaries need none.
              '';
              type = lib.types.listOf lib.types.package;
              default = [ ];
            };
          };
        };

        # Install plugins that are not yet registered; skip already-installed ones
        # and fail loudly when an install fails.
        pluginInstallScript = lib.concatMapStringsSep "\n" (
          plugin:
          let
            refFlags = lib.optionalString (plugin.ref != null) " --ref \"${plugin.ref}\"";
            installInputs = [
              pkgs.git
              pkgs.openssh
              pkgs.curl
              pkgs.gawk
              pkgs.gnutar
              pkgs.gzip
            ];
            pathPrefix = "PATH=\"${lib.makeBinPath (installInputs ++ plugin.buildInputs)}:$PATH\" ";
          in
          ''
            verboseEcho "herdr: checking plugin '${plugin.id}' from '${plugin.source}'"
            if ${herdrPkg}/bin/herdr plugin list --plugin "${plugin.id}" --json \
                | ${pkgs.jq}/bin/jq -e '.result.plugins | length > 0' > /dev/null 2>&1; then
              verboseEcho "herdr: plugin '${plugin.id}' already installed; skipping"
            else
              echo "herdr: installing plugin '${plugin.id}' from '${plugin.source}'" >&2
              echo "herdr: PATH prefix = ${lib.makeBinPath plugin.buildInputs}" >&2
              if ${pathPrefix}run ${herdrPkg}/bin/herdr plugin install "${plugin.source}" --yes${refFlags}; then
                echo "herdr: installed plugin '${plugin.id}' from ${plugin.source}" >&2
              else
                errorEcho "Failed to install herdr plugin '${plugin.id}' from ${plugin.source}"
                errorEcho "Inspect 'journalctl -u home-manager-$USER.service' for the herdr output above."
                exit 1
              fi
            fi
          ''
        ) config.hdwlinux.programs.herdr.plugins;

        # Generate herdr config.toml
        herdrConfig = {
          onboarding = false;

          server = {
            headless_cols = 160;
            headless_rows = 50;
          };

          theme = {
            name = "catppuccin";
            auto_switch = false;
            custom = {
              sidebar_bg = colors.base01;
              panel_bg = colors.base00;
              active_row_bg = colors.base02;
              selection_bg = colors.base03;
              accent = colors.base07;
              text = colors.base05;
              subtext0 = colors.base04;
              surface0 = colors.base02;
              surface1 = colors.base03;
              overlay0 = colors.base04;
              overlay1 = colors.base03;
              mauve = colors.base0E;
              green = colors.base0B;
              yellow = colors.base0A;
              red = colors.base08;
              blue = colors.base0D;
              teal = colors.base0C;
              peach = colors.base09;
            };
          };

          terminal = {
            new_cwd = "follow";
          };

          keys = {
            prefix = "ctrl+b";

            # Pane navigation (prefix-free, arrows + hjkl)
            focus_pane_left = [
              "alt+left"
              "alt+h"
            ];
            focus_pane_down = [
              "alt+down"
              "alt+j"
            ];
            focus_pane_up = [
              "alt+up"
              "alt+k"
            ];
            focus_pane_right = [
              "alt+right"
              "alt+l"
            ];

            # Pane movement (prefix-free, shift + arrows/hjkl)
            swap_pane_left = [
              "alt+shift+left"
              "alt+shift+h"
            ];
            swap_pane_down = [
              "alt+shift+down"
              "alt+shift+j"
            ];
            swap_pane_up = [
              "alt+shift+up"
              "alt+shift+k"
            ];
            swap_pane_right = [
              "alt+shift+right"
              "alt+shift+l"
            ];

            # Pane management (prefix-free)
            zoom = "alt+z";
            close_pane = "alt+w";
            split_vertical = "alt+d";
            split_horizontal = "alt+shift+d";

            # Tabs (prefix-free, brackets avoid arrow conflicts)
            new_tab = "alt+t";
            switch_tab = "alt+1..9";
            next_tab = "alt+]";
            previous_tab = "alt+[";
            close_tab = "alt+x";
            rename_tab = "alt+shift+t";

            # Tab reorder (shift + tab nav)
            move_tab_previous = "alt+shift+[";
            move_tab_next = "alt+shift+]";

            # Workspace (prefix — less frequent)
            new_workspace = "prefix+shift+n";
            rename_workspace = "prefix+shift+w";
            close_workspace = "prefix+shift+d";

            # Session (prefix)
            goto = "prefix+g";
            workspace_picker = "prefix+w";
            toggle_sidebar = "prefix+b";
            detach = "ctrl+shift+d";

            # Plugin action keybindings, bundled with each herdr plugin
            command = lib.concatLists (map (p: p.keybindings) config.hdwlinux.programs.herdr.plugins);
          };

          ui = {
            sidebar_width = 28;
            sidebar_min_width = 20;
            sidebar_max_width = 40;
            sidebar_start_collapsed = false;
            pane_borders = true;
            pane_gaps = true;
            pane_scrollbars = true;
            copy_on_select = true;
            confirm_close = true;
            tab_bar_position = "top";
            hide_tab_bar_when_single_tab = false;
            window_title = "{hostname}: {workspace}";
            status_indicators = "dots";
            mouse_scroll_lines = 3;

            toast = {
              delivery = "herdr";
              delay_seconds = 1;
            };

            sound.enabled = true;
          };

          session = {
            resume_agents_on_restore = true;
          };
        };

        tomlFormat = pkgs.formats.toml { };
        herdrToml = tomlFormat.generate "herdr-config.toml" herdrConfig;
      in
      {
        options.hdwlinux.programs.herdr.plugins = lib.mkOption {
          description = ''
            Herdr plugins to install automatically on home activation. A plugin
            is installed with `herdr plugin install --yes` only when no plugin
            with the same id is already registered.
          '';
          type = lib.types.listOf pluginType;
          default = [ ];
        };

        config = {
          home.packages = [ herdrPkg ];

          home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] pluginInstallScript;

          xdg.configFile."herdr/config.toml".source = herdrToml;
        };
      };
  };

  config.substrate.modules.programs.herdr.mirror = {
    tags = [
      "ai:clients"
      "programming"
    ];

    homeManager =
      { config, lib, ... }:
      {
        hdwlinux.programs.herdr.plugins = [
          {
            id = "mirror";
            source = "nikok6/herdr-mirror";
            keybindings = [
              {
                key = "prefix+alt+m";
                command = "mirror.start";
                description = "mirror: start";
              }
              {
                key = "prefix+alt+shift+p";
                command = "mirror.pause";
                description = "mirror: pause";
              }
              {
                key = "prefix+alt+s";
                command = "mirror.status";
                description = "mirror: status";
              }
              {
                key = "prefix+alt+shift+t";
                command = "mirror.teardown";
                description = "mirror: teardown";
              }
            ];
          }
        ];
      };
  };

  config.substrate.modules.programs.herdr.reviewr = {
    tags = [
      "ai:clients"
      "programming"
    ];

    homeManager =
      { config, lib, ... }:
      {
        hdwlinux.programs.herdr.plugins = [
          {
            id = "persiyanov.reviewr";
            source = "persiyanov/herdr-reviewr";
            keybindings = [
              {
                key = "alt+r";
                command = "persiyanov.reviewr.toggle";
                description = "reviewr: toggle";
              }
            ];
          }
        ];
      };
  };

  config.substrate.modules.programs.herdr.herdr-plus = {
    tags = [
      "ai:clients"
      "programming"
    ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        hdwlinux.programs.herdr.plugins = [
          {
            id = "cloudmanic.herdr-plus";
            source = "cloudmanic/herdr-plus";
            # Prebuilt binary is fine without this, but pins an exact source build.
            buildInputs = [
              pkgs.go
              pkgs.stdenv.cc
            ];
            keybindings = [
              {
                key = "prefix+alt+p";
                command = "cloudmanic.herdr-plus.projects";
                description = "herdr-plus: projects";
              }
            ];
          }
        ];

        xdg.configFile = {
          "herdr/plugins/config/cloudmanic.herdr-plus/config.toml".source = ./plugins/herdr-plus/config.toml;
          "herdr/plugins/config/cloudmanic.herdr-plus/projects/kb.toml".source =
            ./plugins/herdr-plus/projects/kb.toml;
          "herdr/plugins/config/cloudmanic.herdr-plus/projects/nix-config.toml".source =
            ./plugins/herdr-plus/projects/nix-config.toml;
          "herdr/plugins/config/cloudmanic.herdr-plus/projects/nix-private.toml".source =
            ./plugins/herdr-plus/projects/nix-private.toml;
          "herdr/plugins/config/cloudmanic.herdr-plus/projects/substrate.toml".source =
            ./plugins/herdr-plus/projects/substrate.toml;
        };
      };
  };

  config.substrate.modules.programs.herdr.file-viewer = {
    tags = [
      "ai:clients"
      "programming"
    ];

    homeManager =
      { config, lib, ... }:
      {
        hdwlinux.programs.herdr.plugins = [
          {
            id = "herdr-file-viewer";
            source = "smarzban/herdr-file-viewer";
            keybindings = [
              {
                key = "alt+f";
                command = "herdr-file-viewer.open-file-viewer";
                description = "file viewer";
              }
              {
                key = "alt+shift+f";
                command = "herdr-file-viewer.open-file-viewer-tab";
                description = "file viewer (tab)";
              }
            ];
          }
        ];
      };
  };

  config.substrate.modules.programs.herdr.palette = {
    tags = [
      "ai:clients"
      "programming"
    ];

    homeManager =
      { config, lib, pkgs, ... }:
      {
        hdwlinux.programs.herdr.plugins = [
          {
            id = "vjeantet.palette";
            source = "vjeantet/herdr-palette";
            buildInputs = [
              pkgs.cargo
              pkgs.rustc
              pkgs.stdenv.cc
            ];
            keybindings = [
              {
                key = "alt+p";
                command = "vjeantet.palette.open";
                description = "command palette";
              }
            ];
          }
        ];
      };
  };

  config.substrate.modules.programs.herdr.floax = {
    tags = [
      "ai:clients"
      "programming"
    ];

    homeManager =
      { config, lib, pkgs, ... }:
      {
        home.packages = [
          pkgs.dtach
          pkgs.jq
        ];

        hdwlinux.programs.herdr.plugins = [
          {
            id = "herdr-floax";
            source = "Tyru5/herdr-floax";
            buildInputs = [
              pkgs.cargo
              pkgs.rustc
              pkgs.stdenv.cc
            ];
            keybindings = [
              {
                key = "alt+backtick";
                command = "herdr-floax.toggle";
                description = "toggle floating terminal";
              }
            ];
          }
        ];
      };
  };
}
