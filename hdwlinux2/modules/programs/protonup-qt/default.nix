{
  config.substrate.modules.programs.protonup-qt = {
    tags = [ "gui" "gaming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.protonup-qt ];
      };
  };
}

