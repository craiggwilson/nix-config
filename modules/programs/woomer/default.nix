{
  config.substrate.modules.programs.woomer = {
    tags = [ "gui" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.woomer ];
      };
  };
}

