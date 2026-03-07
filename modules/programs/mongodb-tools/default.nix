{
  config.substrate.modules.programs.mongodb-tools = {
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

