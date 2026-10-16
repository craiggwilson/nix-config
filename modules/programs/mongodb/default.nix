{
  config.substrate.modules.programs.mongodb = {
    provides = [ "programs:mongodb" "programming" ];
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
