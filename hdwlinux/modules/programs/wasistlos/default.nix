{
  config.substrate.modules.programs.wasistlos = {
    tags = [ "gui" "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.wasistlos ];
      };
  };
}

