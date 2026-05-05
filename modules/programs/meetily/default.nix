{
  config.substrate.modules.programs.meetily = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.meetily ];
      };
  };
}
