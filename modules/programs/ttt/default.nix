{
  config.substrate.modules.programs.ttt = {
    tags = [ "profile:programming" ];

    homeManager =
      {
        pkgs,
        ...
      }:
      {
        home.packages = [ pkgs.ttt ];

        xdg.configFile = {
          "ttt/plugins/jujutsu/plugin.ttt.json".source = ./plugins/jujutsu/plugin.ttt.json;
          "ttt/plugins/jujutsu/init.lua".source = ./plugins/jujutsu/init.lua;
          "ttt/settings.json".text = builtins.toJSON {
            version = 1;
            sidebar.panelOrder = [
              "explorer"
              "search"
              "plugin.jujutsu"
            ];
          };
        };
      };
  };
}
