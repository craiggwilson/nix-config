{
  config.substrate.modules.programs.freetube = {
    tags = [ "gui" "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.freetube ];
      };
  };
}

