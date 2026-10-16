{
  config.substrate.modules.programs.protonup-qt = {
    provides = [ "programs:protonup-qt" "gaming" ];
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
