{
  config.substrate.modules.programs.openspec = {
    provides = [ "ai:clients" ];
    requires = [ "programming" ];
    tags = [
      "programming"
      "ai:clients"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.openspec ];
      };
  };
}
