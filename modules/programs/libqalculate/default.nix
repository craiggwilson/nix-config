{
  config.substrate.modules.programs.libqalculate = {
    provides = [ "programs:libqalculate" "gui" ];
    tags = [ "desktop" ];

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.libqalculate ];
    };
  };
}
