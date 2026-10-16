{
  config.substrate.modules.programs.meld = {
    provides = [ "programming" ];
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
