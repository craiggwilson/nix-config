{
  config.substrate.modules.programs.woomer = {
    provides = [ "gui" ];
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.woomer ];
      };
  };
}
