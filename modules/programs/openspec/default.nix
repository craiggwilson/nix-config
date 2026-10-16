{
  config.substrate.modules.programs.openspec = {
    provides = [ "programs:openspec" "ai:clients" ];
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
