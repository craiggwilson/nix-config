{
  config.substrate.modules.programs.zoxide = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        hdwlinux.shell.zsh.initLines = [
          {
            prio = 100;
            text = "eval \"$(${pkgs.zoxide}/bin/zoxide init zsh )\"";
          }
        ];
        hdwlinux.shell.bash.initLines = [
          {
            prio = 580;
            text = "eval \"$(${pkgs.zoxide}/bin/zoxide init bash )\"";
          }
        ];
      };

    homeManager =
      { config, ... }:
      {
        programs.zoxide = {
          enable = true;
          enableBashIntegration = config.programs.bash.enable;
          enableZshIntegration = config.programs.zsh.enable;
        };
      };
  };
}

