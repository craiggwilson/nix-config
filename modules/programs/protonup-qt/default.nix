{
  config.substrate.modules.programs.protonup-qt = {
    tags = [ "gui" "gaming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.protonup-qt ];
      };
  };
}

