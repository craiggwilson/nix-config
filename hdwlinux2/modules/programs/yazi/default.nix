{
  config.substrate.modules.programs.yazi = {
    tags = [ "programming" ];

    homeManager =
      { config, ... }:
      {
        programs.yazi = {
          enable = true;
          enableBashIntegration = config.programs.bash.enable;
          enableZshIntegration = config.programs.zsh.enable;
          settings = {
            manager = {
              show_hidden = true;
              sort_by = "natural";
              sort_dir_first = true;
            };
          };
        };
      };
  };
}

