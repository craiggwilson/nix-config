{
  config.substrate.modules.programs.meld = {
    tags = [ "gui" "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.meld ];
      };
  };
}

