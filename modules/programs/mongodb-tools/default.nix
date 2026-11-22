{
  config.substrate.modules.programs.mongodb-tools = {
    tags = [
      "profile:database-development"
      "profile:programming"
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
