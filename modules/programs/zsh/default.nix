{
  config.substrate.modules.programs.zsh = {
    tags = [ "programming" ];

    nixos =
      { pkgs, ... }:
      {
        programs.zsh.enable = true;
        users.defaultUserShell = pkgs.zsh;
      };

    homeManager =
      { config, ... }:
      {
        programs.zsh = {
          enable = true;
          dotDir = "${config.xdg.configHome}/zsh";
          enableCompletion = true;
          enableVteIntegration = true;
          autosuggestion.enable = true;
          history = {
            size = 10000;
            ignoreAllDups = true;
            path = "${config.xdg.stateHome}/zsh_history";
            ignorePatterns = [
              "cd *"
              "cp *"
              "exit"
              "ls *"
              "mv *"
              "pkill *"
              "rm *"
            ];
          };
          initContent = ''
            bindkey "^[[1;5C"    forward-word
            bindkey "^[[1;5D"    backward-word
            bindkey  "^[[1;6C"  end-of-line
            bindkey  "^[[1;6D"   beginning-of-line

            bindkey  "^[[F"      end-of-line
            bindkey  "^[[H"      beginning-of-line

            source ${./transient-prompt.zsh}
          '';
          syntaxHighlighting = {
            enable = true;

          };
        };
      };
  };
}
