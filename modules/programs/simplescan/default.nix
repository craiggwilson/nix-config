{
  config.substrate.modules.programs.simplescan = {
    tags = [ "gui" "scanning" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.simple-scan ];
      };
  };
}

