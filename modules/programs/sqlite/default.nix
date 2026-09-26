{
  config.substrate.modules.programs.sqlite = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.sqlite ];
      };
  };
}
