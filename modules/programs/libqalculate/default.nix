{
  config.substrate.modules.programs.libqalculate = {
    provides = [ "gui" ];
    tags = [ "desktop" ];

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.libqalculate ];
    };
  };
}
