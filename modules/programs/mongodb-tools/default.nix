{
  config.substrate.modules.programs.mongodb-tools = {
    provides = [
      "programs:mongodb-tools"
      "programming"
    ];
    requires = [ "profiles:work" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.mongosh
          pkgs.mongodb-tools
        ];
      };
  };
}
