{
  config.substrate.modules.programs.mongodb = {
    tags = [ "programming" "users:craig:work" ];

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

