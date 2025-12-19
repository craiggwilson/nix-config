{
  config.substrate.modules.programs.calibre = {
    tags = [ "gui" "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.calibre ];
      };
  };
}

