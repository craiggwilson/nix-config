{
  config.substrate.modules.programs.fzf = {
    tags = [ "programming" ];

    homeManager =
      { config, ... }:
      {
        programs.fzf = {
          enable = true;
          enableBashIntegration = config.programs.bash.enable;
          enableZshIntegration = config.programs.zsh.enable;
        };
      };
  };
}

