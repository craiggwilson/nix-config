{
  config.substrate.modules.programs.yazi = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      let
        toml = pkgs.formats.toml { };
      in
      {
        packages = [ pkgs.yazi ];

        hdwlinux.shell.zsh.initLines = [
          {
            prio = 420;
            text = ''
              function y() {
                local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
                command yazi "$@" --cwd-file="$tmp"
                if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
                  builtin cd -- "$cwd"
                fi
                rm -f -- "$tmp"
              }
            '';
          }
        ];
        hdwlinux.shell.bash.initLines = [
          {
            prio = 520;
            text = ''
              function y() {
                local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
                command yazi "$@" --cwd-file="$tmp"
                if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
                  builtin cd -- "$cwd"
                fi
                rm -f -- "$tmp"
              }
            '';
          }
        ];

        files.".config/yazi/yazi.toml".source = toml.generate "yazi.toml" {
          mgr.ratio = [ 0 2 8 ];
        };

        files.".config/yazi/keymap.toml".source = toml.generate "keymap.toml" {
          mgr.prepend_keymap = [
            {
              on = [ "<Enter>" ];
              run = "plugin smart-enter";
              desc = "Enter the child directory, or open the file";
            }
          ];
        };

        files.".config/yazi/plugins/smart-enter.yazi".source = ./plugins/smart-enter.yazi;
      };
  };
}
