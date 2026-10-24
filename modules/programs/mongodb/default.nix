{
  config.substrate.modules.programs.mongodb = {
    tags = [
      "profile:programming"
      "user:craig"
      "profile:work"
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
