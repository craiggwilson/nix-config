{
  config.substrate.modules.programs.mongodb = {
    tags = [
      "profile:database-development"
      "profile:programming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          mongodb-ce
          mongosh
          mongodb-tools
          hdwlinux.mongo-orchestration
        ];
      };
  };
}
