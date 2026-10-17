{
  config.substrate.modules.programs.openspec = {
    provides = [
      "programs:openspec"
      "ai:clients"
    ];
    requires = [ "programming" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.openspec ];
      };
  };
}
