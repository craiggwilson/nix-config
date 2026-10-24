{
  config.substrate.modules.programs.atlas-cli = {
    tags = [
      "profile:programming"
      "user:craig"
      "profile:work"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.atlas-cli ];
      };
  };
}
