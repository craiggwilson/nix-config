{
  config.substrate.modules.programs.bash = {
    provides = [ "core:home" ];
    homeManager =
      { config, ... }:
      {
        programs.bash = {
          enable = true;
          enableCompletion = true;
          historyControl = [
            "erasedups"
            "ignoredups"
            "ignorespace"
          ];
          historyFile = "${config.xdg.dataHome}/bash/history";
          historyFileSize = 10000;
          historySize = 10000;
        };
      };
  };
}
