{
  config.substrate.modules.programs.libqalculate = {
    tags = [ "desktop" ];

    perUser = { pkgs, ... }: {
      packages = [ pkgs.libqalculate ];
    };
  };
}
