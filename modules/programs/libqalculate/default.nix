{
  config.substrate.modules.programs.libqalculate = {
    tags = [ "desktop" ];

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.libqalculate ];
    };
  };
}
