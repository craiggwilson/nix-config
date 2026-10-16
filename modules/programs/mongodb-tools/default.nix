{
  config.substrate.modules.programs.mongodb-tools = {
    provides = [ "programs:mongodb-tools" "programming" ];
    requires = [ "profiles:work" ];
    tags = [
      "programming"
      "users:craig:work"
    ];

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
