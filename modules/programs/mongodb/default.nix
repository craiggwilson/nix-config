{
  config.substrate.modules.programs.mongodb = {
    provides = [ "programming" ];
    requires = [ "profiles:work" ];
    tags = [
      "programming"
      "users:craig:work"
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
