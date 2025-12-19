{
  config.substrate.modules.programs.discord = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.discord ];
      };
  };
}

