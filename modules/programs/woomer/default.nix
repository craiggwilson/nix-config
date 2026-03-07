{
  config.substrate.modules.programs.woomer = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.woomer ];
      };
  };
}

