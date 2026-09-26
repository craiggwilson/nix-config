{
  config.substrate.modules.programs.zellij = {
    tags = [ "programming" ];

    perUser =
      { config, lib, pkgs, ... }:
      let
        toKDL =
          (import ../../../lib/kdl.nix { inherit lib; }).toKDL
            {
              # Matches the escape flags HM derived from stateVersion < 26.11.
              escapeBackslashes = false;
              escapeTabs = false;
            };

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

        settings = {
          copy_on_select = true;
          default_shell = lib.getExe pkgs.zsh;
          mouse_mode = true;
          pane_frames = true;
          scroll_buffer_size = 10000;
          show_startup_tips = false;
          theme = "hdwlinux";
        };
      in
      {
        packages = [ pkgs.zellij ];

        files.".config/zellij/config.kdl".text =
          (toKDL settings)
          + "\n// extraConfig\n\n"
          + keybindsKdl;

        files.".config/zellij/themes/hdwlinux.kdl".text =
          toKDL {
            themes.hdwlinux = import ./_theme.nix config.hdwlinux.theme.colors;
          };
      };
  };
}
