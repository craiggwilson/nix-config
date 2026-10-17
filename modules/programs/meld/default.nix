{
  config.substrate.modules.programs.meld = {
    provides = [
      "programs:meld"
      "programming"
    ];
    requires = [ "gui" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.meld ];
      };
  };
}
