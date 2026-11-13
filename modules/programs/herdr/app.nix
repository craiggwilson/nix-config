{
  config.substrate.modules.programs.herdr.app = {
    tags = [
      "profile:ai"
      "profile:programming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.herdr-app ];
      };
  };
}
