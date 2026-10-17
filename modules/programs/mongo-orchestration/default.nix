{
  config.substrate.modules.programs.mongo-orchestration = {
    provides = [
      "programs:mongo-orchestration"
      "profiles:work"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.mongo-orchestration ];

        xdg.dataFile."mongo-orchestration/configurations" = {
          source = ./configurations;
          recursive = true;
        };

        home.sessionVariables = {
          MONGO_ORCHESTRATION_HOME = "$XDG_DATA_HOME/mongo-orchestration";
        };
      };
  };
}
