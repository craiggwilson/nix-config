{
  config.substrate.modules.programs.fzf = {
    provides = [ "programs:fzf" "programming" ];
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
