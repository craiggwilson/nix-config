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
