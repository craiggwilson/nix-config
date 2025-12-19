{
  config.substrate.modules.programs.nasc = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.stable.nasc ];
      };
  };
}
