{
  config.substrate.modules.programs.mongodb-tools = {
    tags = [
      "programming"
      "users:craig:work"
    ];

    perUser =
      { pkgs, ... }:
      {
        packages = [
          pkgs.mongosh
          pkgs.mongodb-tools
        ];
      };
  };
}

