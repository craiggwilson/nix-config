{
  config.substrate.modules.programs.midivisualizer = {
    tags = [ "audio:midi" "gui" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.midivisualizer ];
      };
  };
}

