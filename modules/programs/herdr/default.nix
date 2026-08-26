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
            focus_pane_left = [ "alt+left" "alt+h" ];
            focus_pane_down = [ "alt+down" "alt+j" ];
            focus_pane_up = [ "alt+up" "alt+k" ];
            focus_pane_right = [ "alt+right" "alt+l" ];

            # Pane movement (prefix-free, shift + arrows/hjkl)
            swap_pane_left = [ "alt+shift+left" "alt+shift+h" ];
            swap_pane_down = [ "alt+shift+down" "alt+shift+j" ];
            swap_pane_up = [ "alt+shift+up" "alt+shift+k" ];
            swap_pane_right = [ "alt+shift+right" "alt+shift+l" ];

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

            # Plugins
            command = [
              # jj-workspace
              {
                key = "alt+n";
                type = "plugin_action";
                command = "nathanflurry.jj-workspace.new";
                description = "new jj workspace";
              }
              {
                key = "alt+shift+n";
                type = "plugin_action";
                command = "nathanflurry.jj-workspace.remove";
                description = "remove jj workspace";
              }
              # file-viewer
              {
                key = "alt+f";
                type = "plugin_action";
                command = "herdr-file-viewer.open-file-viewer";
                description = "file viewer";
              }
              {
                key = "alt+shift+f";
                type = "plugin_action";
                command = "herdr-file-viewer.open-file-viewer-tab";
                description = "file viewer (tab)";
              }
              # herdr-bar
              {
                key = "alt+p";
                type = "plugin_action";
                command = "herdr-bar.open";
                description = "command bar";
              }
              # mirror
              {
                key = "prefix+alt+m";
                type = "plugin_action";
                command = "mirror.start";
                description = "mirror: start";
              }
              {
                key = "prefix+alt+shift+p";
                type = "plugin_action";
                command = "mirror.pause";
                description = "mirror: pause";
              }
              {
                key = "prefix+alt+s";
                type = "plugin_action";
                command = "mirror.status";
                description = "mirror: status";
              }
              {
                key = "prefix+alt+shift+t";
                type = "plugin_action";
                command = "mirror.teardown";
                description = "mirror: teardown";
              }
            ];
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
        home.packages = [
          inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];

        xdg.configFile."herdr/config.toml".source = herdrToml;

        home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${lib.concatStringsSep "\n" (map (plugin: ''
            $DRY_RUN_CMD herdr plugin install --yes ${plugin} || true
          '') [
            "NathanFlurry/herdr-plugin-jj-workspace"
            "smarzban/herdr-file-viewer"
            "nikok6/herdr-mirror"
            "jeffarese/herdr-bar"
          ])}
        '';
      };
  };
}
