{
  config.substrate.modules.programs.meld = {
    provides = [ "programs:meld" "programming" ];
    requires = [ "gui" ];
    tags = [
      "gui"
      "programming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.meld ];
      };
  };
}
