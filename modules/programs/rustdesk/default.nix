{
  config.substrate.modules.programs.rustdesk = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.rustdesk ];
      };
  };
}
