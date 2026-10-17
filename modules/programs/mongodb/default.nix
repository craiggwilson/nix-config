{
  config.substrate.modules.programs.mongodb = {
    provides = [
      "programs:mongodb"
      "programming"
    ];
    requires = [ "profiles:work" ];
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
