{
  config.substrate.modules.programs.zellij = {
    tags = [ "programming" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors;

        # Parse a bare 6-character hex string into "R G B" for zellij KDL themes.
        hexToRgb =
          hex:
          let
            hexDigits = {
              "0" = 0;
              "1" = 1;
              "2" = 2;
              "3" = 3;
              "4" = 4;
              "5" = 5;
              "6" = 6;
              "7" = 7;
              "8" = 8;
              "9" = 9;
              "a" = 10;
              "b" = 11;
              "c" = 12;
              "d" = 13;
              "e" = 14;
              "f" = 15;
              "A" = 10;
              "B" = 11;
              "C" = 12;
              "D" = 13;
              "E" = 14;
              "F" = 15;
            };
            parseByte = s: hexDigits.${builtins.substring 0 1 s} * 16 + hexDigits.${builtins.substring 1 1 s};
            r = parseByte (builtins.substring 0 2 hex);
            g = parseByte (builtins.substring 2 2 hex);
            b = parseByte (builtins.substring 4 2 hex);
          in
          "${toString r} ${toString g} ${toString b}";

        # Build a UI component block with base, background, and emphasis colors.
        mkComponent =
          {
            base,
            background,
            emphasis_0,
            emphasis_1,
            emphasis_2,
            emphasis_3,
          }:
          ''
            base ${hexToRgb base}
            background ${hexToRgb background}
            emphasis_0 ${hexToRgb emphasis_0}
            emphasis_1 ${hexToRgb emphasis_1}
            emphasis_2 ${hexToRgb emphasis_2}
            emphasis_3 ${hexToRgb emphasis_3}
          '';

        # Accent and palette assignments matching the old tmux theme intent:
        #   themeColor = base0D (blue)
        #   bg         = base00 (base background)
        #   mid        = base02 (surface0)
        #   fg         = base04 (surface2 — subdued foreground)
        themeKdl = ''
          themes {
            hdwlinux {
              text_unselected {
          ${
            mkComponent {
              base = colors.base04;
              background = colors.base00;
              emphasis_0 = colors.base0D;
              emphasis_1 = colors.base0E;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0A;
            }
          }    }
              text_selected {
          ${
            mkComponent {
              base = colors.base05;
              background = colors.base02;
              emphasis_0 = colors.base0D;
              emphasis_1 = colors.base0E;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0A;
            }
          }    }
              ribbon_unselected {
          ${
            mkComponent {
              base = colors.base04;
              background = colors.base02;
              emphasis_0 = colors.base0D;
              emphasis_1 = colors.base0E;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0A;
            }
          }    }
              ribbon_selected {
          ${
            mkComponent {
              base = colors.base00;
              background = colors.base0D;
              emphasis_0 = colors.base00;
              emphasis_1 = colors.base0E;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0A;
            }
          }    }
              table_title {
          ${
            mkComponent {
              base = colors.base0D;
              background = colors.base00;
              emphasis_0 = colors.base0D;
              emphasis_1 = colors.base0E;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0A;
            }
          }    }
              table_cell_unselected {
          ${
            mkComponent {
              base = colors.base04;
              background = colors.base00;
              emphasis_0 = colors.base0D;
              emphasis_1 = colors.base0E;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0A;
            }
          }    }
              table_cell_selected {
          ${
            mkComponent {
              base = colors.base05;
              background = colors.base02;
              emphasis_0 = colors.base0D;
              emphasis_1 = colors.base0E;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0A;
            }
          }    }
              list_unselected {
          ${
            mkComponent {
              base = colors.base04;
              background = colors.base00;
              emphasis_0 = colors.base0D;
              emphasis_1 = colors.base0E;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0A;
            }
          }    }
              list_selected {
          ${
            mkComponent {
              base = colors.base05;
              background = colors.base02;
              emphasis_0 = colors.base0D;
              emphasis_1 = colors.base0E;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0A;
            }
          }    }
              frame_unselected {
          ${
            mkComponent {
              base = colors.base02;
              background = colors.base00;
              emphasis_0 = colors.base0D;
              emphasis_1 = colors.base0E;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0A;
            }
          }    }
              frame_selected {
          ${
            mkComponent {
              base = colors.base0D;
              background = colors.base00;
              emphasis_0 = colors.base0D;
              emphasis_1 = colors.base0E;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0A;
            }
          }    }
              frame_highlight {
          ${
            mkComponent {
              base = colors.base0E;
              background = colors.base00;
              emphasis_0 = colors.base0D;
              emphasis_1 = colors.base0E;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0A;
            }
          }    }
              exit_code_success {
          ${
            mkComponent {
              base = colors.base0B;
              background = colors.base00;
              emphasis_0 = colors.base0B;
              emphasis_1 = colors.base0B;
              emphasis_2 = colors.base0B;
              emphasis_3 = colors.base0B;
            }
          }    }
              exit_code_error {
          ${
            mkComponent {
              base = colors.base08;
              background = colors.base00;
              emphasis_0 = colors.base08;
              emphasis_1 = colors.base08;
              emphasis_2 = colors.base08;
              emphasis_3 = colors.base08;
            }
          }    }
              multiplayer_user_colors {
                player_1 ${hexToRgb colors.base0D}
                player_2 ${hexToRgb colors.base0B}
                player_3 ${hexToRgb colors.base0A}
                player_4 ${hexToRgb colors.base0E}
                player_5 ${hexToRgb colors.base0C}
                player_6 ${hexToRgb colors.base09}
                player_7 ${hexToRgb colors.base08}
                player_8 ${hexToRgb colors.base0F}
                player_9 ${hexToRgb colors.base04}
                player_10 ${hexToRgb colors.base05}
              }
            }
          }
        '';
      in
      {
        programs.zellij = {
          enable = true;
          enableBashIntegration = config.programs.bash.enable;
          enableZshIntegration = config.programs.zsh.enable;
          extraConfig = themeKdl;
          settings = {
            copy_on_select = true;
            default_shell = "${pkgs.zsh}/bin/zsh";
            mouse_mode = true;
            pane_frames = true;
            scroll_buffer_size = 10000;
            show_startup_tips = false;
            theme = "hdwlinux";
          };
        };
      };
  };
}
