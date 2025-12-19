{
  config.substrate.modules.programs.zoxide = {
    tags = [ "programming" ];

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

