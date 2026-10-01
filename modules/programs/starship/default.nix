{
  config.substrate.modules.programs.starship = {
    tags = [ "programming" ];

    homeManager =
      { config, ... }:
      {
        programs.starship = {
          enable = true;
          enableBashIntegration = config.programs.bash.enable;
          enableZshIntegration = config.programs.zsh.enable;

        };
      };
  };
}
