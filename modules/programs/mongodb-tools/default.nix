{
  config.substrate.modules.programs.mongodb-tools = {
    tags = [
      "profile:programming"
      "user:craig"
      "profile:work"
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
