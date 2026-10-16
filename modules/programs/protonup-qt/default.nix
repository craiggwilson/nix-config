{
  config.substrate.modules.programs.protonup-qt = {
    provides = [ "gaming" ];
    requires = [ "gui" ];
    tags = [
      "gui"
      "gaming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.protonup-qt ];
      };
  };
}
