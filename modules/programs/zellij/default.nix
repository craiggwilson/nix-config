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
        # Remap Alt+f (toggle floating panes) to Alt+`; Ctrl+q detaches instead of quitting
        keybindsKdl = ''
          keybinds {
              unbind "Ctrl q"

              shared_except "locked" {
                  bind "Alt `" { ToggleFloatingPanes; }
                  bind "Ctrl Shift d" { Detach; }
                  bind "Ctrl Shift Alt q" { Quit; }
                  bind "Alt Shift Left" { MoveTab "Left"; }
                  bind "Alt Shift Right" { MoveTab "Right"; }
              }

              tab {
                  bind "d" {
                    NewTab {
                      layout "dev"
                    }
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
          extraConfig = keybindsKdl;
          settings = {
            copy_on_select = true;
            default_shell = "${pkgs.zsh}/bin/zsh";
            mouse_mode = true;
            pane_frames = true;
            scroll_buffer_size = 10000;
            show_startup_tips = false;
            theme = "hdwlinux";
          };
          themes.hdwlinux.themes.hdwlinux = (import ./_theme.nix config.hdwlinux.theme.colors);

          layouts.dev = {
            layout = {
              _children = [
                {
                  pane = {
                    size = 1;
                    borderless = true;
                    plugin = {
                      location = "zellij:tab-bar";
                    };
                  };
                }
                {
                  pane = {
                    _props = {
                      stacked = true;
                    };
                    _children = [
                      {
                        pane = {
                          _props = {
                            name = "opencode";
                          };
                          focus = true;
                          #command = "opencode";
                        };
                      }
                      {
                        pane = {
                          _props = {
                            name = "files";
                          };
                          command = "${lib.getExe pkgs.yazi}";
                        };
                      }
                    ];
                  };
                }
                {
                  floating_panes = {
                    _children = [
                      {
                        pane = {
                          _props = {
                            name = "terminal";
                          };
                          command = "${pkgs.zsh}/bin/zsh";
                        };
                      }
                    ];
                  };
                }
                {
                  pane = {
                    size = 2;
                    borderless = true;
                    plugin = {
                      location = "zellij:status-bar";
                    };
                  };
                }
              ];
            };
          };
        };

      };
  };
}
