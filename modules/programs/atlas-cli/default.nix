{
  config.substrate.modules.programs.atlas-cli = {
    tags = [
      "profile:database-development"
      "profile:programming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.atlas-cli ];
      };
  };
}
