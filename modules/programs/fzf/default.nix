{
  config.substrate.modules.programs.fzf = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.fzf ];

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
  };
}

