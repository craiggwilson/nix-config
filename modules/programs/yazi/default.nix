{
  config.substrate.modules.programs.yazi = {
    tags = [ "programming" ];

    # Yazi config (keymap/settings/smart-enter plugin) stays home-manager-
    # side until the yazi config wave; only the y() wrapper moves here.
    perUser =
      { ... }:
      let
        wrapper = ''
          function y() {
            local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
            command yazi "$@" --cwd-file="$tmp"
            if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
              builtin cd -- "$cwd"
            fi
            rm -f -- "$tmp"
          }
        '';
      in
      {
        hdwlinux.shell.zsh.initLines = [
          {
            prio = 420;
            text = wrapper;
          }
        ];
        hdwlinux.shell.bash.initLines = [
          {
            prio = 520;
            text = wrapper;
          }
        ];
      };

    homeManager =
      { config, ... }:
      {
        programs.yazi = {
          enable = true;
          enableBashIntegration = config.programs.bash.enable;
          enableZshIntegration = config.programs.zsh.enable;
          keymap.mgr.prepend_keymap = [
            {
              on = [ "<Enter>" ];
              run = "plugin smart-enter";
              desc = "Enter the child directory, or open the file";
            }
          ];
          plugins."smart-enter" = ./plugins/smart-enter.yazi;
          settings.mgr.ratio = [ 0 2 8 ];
          shellWrapperName = "y";
        };
      };
  };
}
