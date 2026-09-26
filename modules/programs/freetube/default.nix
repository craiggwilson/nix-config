{
  config.substrate.modules.programs.freetube = {
    tags = [ "gui" "users:craig:personal" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.freetube ];
      };
  };
}

