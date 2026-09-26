{
  config.substrate.modules.programs.fzf = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        hdwlinux.shell.zsh.initLines = [
          {
            prio = 300;
            text = ''
              if [[ $options[zle] = on ]]; then
                source <(${pkgs.fzf}/bin/fzf --zsh)
              fi
            '';
          }
        ];
        hdwlinux.shell.bash.initLines = [
          {
            prio = 500;
            text = ''
              if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
                eval "$(${pkgs.fzf}/bin/fzf --bash)"
              fi
            '';
          }
        ];
      };

    homeManager =
      { config, ... }:
      {
        programs.fzf = {
          enable = true;
          # Integration flags go inert with HM's zsh/bash modules off;
          # shell lines live in the perUser blocks above.
          enableBashIntegration = config.programs.bash.enable;
          enableZshIntegration = config.programs.zsh.enable;
        };
      };
  };
}

