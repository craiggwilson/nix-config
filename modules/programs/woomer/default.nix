{
  config.substrate.modules.programs.woomer = {
    provides = [
      "programs:woomer"
      "gui"
    ];
    requires = [ "gui" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.woomer ];
      };
  };
}
