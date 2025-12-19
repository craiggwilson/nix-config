{
  config.substrate.modules.programs.slack = {
    tags = [ "gui" "users:craig:work" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.slack ];
      };
  };
}

