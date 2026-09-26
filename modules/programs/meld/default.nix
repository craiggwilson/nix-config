{
  config.substrate.modules.programs.meld = {
    tags = [ "gui" "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.meld ];
      };
  };
}

