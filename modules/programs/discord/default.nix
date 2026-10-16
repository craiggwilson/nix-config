{
  config.substrate.modules.programs.discord = {
    provides = [ "programs:discord" "gui" ];
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.discord ];
      };
  };
}
