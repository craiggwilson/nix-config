{
  config.substrate.modules.programs.woomer = {
    provides = [
      "programs:woomer"
      "gui"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.woomer ];
      };
  };
}
