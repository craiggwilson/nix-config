{
  config.substrate.modules.programs.slack = {
    tags = [ "gui" "users:craig:work" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.slack ];
      };
  };
}

