{
  config.substrate.modules.programs.obsidian = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.obsidian ];
      };
  };
}

