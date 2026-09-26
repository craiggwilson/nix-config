{
  config.substrate.modules.programs.nasc = {
    tags = [ "gui" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.stable.nasc ];
      };
  };
}
